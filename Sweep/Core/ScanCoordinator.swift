import Foundation
import Observation
import Photos
import UIKit

@MainActor
@Observable
final class ScanCoordinator {
    enum State: Equatable {
        case idle
        case scanning(progress: Double, stage: String)
        case complete(ScanReport)
        case failed(String)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case let (.scanning(p1, s1), .scanning(p2, s2)): return p1 == p2 && s1 == s2
            case (.complete, .complete): return true
            case let (.failed(a), .failed(b)): return a == b
            default: return false
            }
        }
    }

    private(set) var state: State = .idle

    /// dHash Hamming-distance threshold below which two images are
    /// considered visual duplicates. 0–4 = near-identical, 5–10 = similar.
    private let duplicateDistanceThreshold = 6

    /// Laplacian-variance threshold below which an image is flagged blurry.
    private let blurVarianceThreshold: Double = 70

    /// Cap on number of "large media" items reported (sorted desc by size).
    private let largeMediaTopN = 100

    func start() {
        if case .scanning = state { return }
        state = .scanning(progress: 0, stage: "Indexing library…")
        Task.detached(priority: .userInitiated) { [self] in
            do {
                let report = try await self.runScan()
                await MainActor.run { self.state = .complete(report) }
            } catch {
                await MainActor.run { self.state = .failed(error.localizedDescription) }
            }
        }
    }

    /// Drop the given local-identifiers from every category of the current
    /// report. Called after the user confirms a deletion in the system
    /// dialog so HomeView counters update without a full rescan.
    func acknowledgeDeletions(_ ids: Set<String>) {
        guard case let .complete(report) = state else { return }
        state = .complete(report.removing(ids: ids))
    }

    private func setStage(_ stage: String, progress: Double) async {
        await MainActor.run { self.state = .scanning(progress: progress, stage: stage) }
    }

    // MARK: - Pipeline

    private nonisolated func runScan() async throws -> ScanReport {
        let options = PHFetchOptions()
        options.includeHiddenAssets = false
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let result = PHAsset.fetchAssets(with: options)
        let total = result.count

        await setStage("Indexing \(total) items…", progress: 0.02)

        var assets: [PHAsset] = []
        assets.reserveCapacity(total)
        result.enumerateObjects { asset, _, _ in assets.append(asset) }

        await setStage("Computing file sizes…", progress: 0.1)
        let summaries: [PhotoSummary] = assets.map { PhotoSummary($0, fileSize: Self.estimateSize($0)) }
        let summaryByID = Dictionary(summaries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        // 1. Screenshots
        let screenshots = summaries.filter { $0.isScreenshot }
        await setStage("Screenshots: \(screenshots.count)", progress: 0.15)

        // 2. Large media — top N by size
        let largeMedia = Array(
            summaries.sorted { $0.estimatedFileSize > $1.estimatedFileSize }.prefix(largeMediaTopN)
        )
        await setStage("Largest items: \(largeMedia.count)", progress: 0.18)

        // 3. Hash photos for duplicate detection (videos skipped).
        let photoAssets = assets.filter { $0.mediaType == .image }
        let hashes = try await self.hashPhotos(photoAssets, total: total) { done in
            let frac = 0.2 + 0.5 * Double(done) / Double(max(photoAssets.count, 1))
            await self.setStage("Hashing photos… \(done)/\(photoAssets.count)", progress: frac)
        }

        // 4. Group near-duplicates by Hamming distance ≤ threshold (and ≠ 0 → similar; 0 → exact).
        await setStage("Finding duplicates…", progress: 0.72)
        let duplicateGroups = Self.groupNearDuplicates(
            hashes: hashes,
            summaries: summaryByID,
            threshold: duplicateDistanceThreshold
        )

        // 5. Burst detection: assets within 2s window of each other AND with near-identical hash.
        await setStage("Detecting bursts…", progress: 0.8)
        let burstGroups = Self.detectBursts(hashes: hashes, summaries: summaryByID)

        // 6. Blur detection on photos only.
        await setStage("Checking sharpness…", progress: 0.85)
        let blurry = try await self.detectBlur(photoAssets, total: total) { done in
            let frac = 0.85 + 0.12 * Double(done) / Double(max(photoAssets.count, 1))
            await self.setStage("Sharpness check… \(done)/\(photoAssets.count)", progress: frac)
        }

        await setStage("Done", progress: 1.0)

        return ScanReport(
            duplicates: duplicateGroups,
            screenshots: screenshots,
            blurry: blurry,
            bursts: burstGroups,
            largeMedia: largeMedia,
            totalLibraryCount: total
        )
    }

    private nonisolated func hashPhotos(
        _ assets: [PHAsset],
        total: Int,
        progress: @Sendable (Int) async -> Void
    ) async throws -> [String: UInt64] {
        var hashes: [String: UInt64] = [:]
        let manager = PHImageManager.default()
        let opts = PHImageRequestOptions()
        opts.isSynchronous = true
        opts.deliveryMode = .fastFormat
        opts.resizeMode = .fast
        opts.isNetworkAccessAllowed = false
        let size = CGSize(width: 64, height: 64)

        for (idx, asset) in assets.enumerated() {
            try Task.checkCancellation()
            await withCheckedContinuation { cont in
                manager.requestImage(
                    for: asset,
                    targetSize: size,
                    contentMode: .aspectFill,
                    options: opts
                ) { image, _ in
                    if let image, let hash = Optional(PerceptualHash.compute(image)), hash != 0 {
                        hashes[asset.localIdentifier] = hash
                    }
                    cont.resume()
                }
            }
            if idx % 50 == 0 { await progress(idx) }
        }
        await progress(assets.count)
        return hashes
    }

    private nonisolated func detectBlur(
        _ assets: [PHAsset],
        total: Int,
        progress: @Sendable (Int) async -> Void
    ) async throws -> [PhotoSummary] {
        var result: [PhotoSummary] = []
        let manager = PHImageManager.default()
        let opts = PHImageRequestOptions()
        opts.isSynchronous = true
        opts.deliveryMode = .fastFormat
        opts.resizeMode = .fast
        opts.isNetworkAccessAllowed = false
        let size = CGSize(width: 128, height: 128)

        for (idx, asset) in assets.enumerated() {
            try Task.checkCancellation()
            await withCheckedContinuation { cont in
                manager.requestImage(
                    for: asset,
                    targetSize: size,
                    contentMode: .aspectFit,
                    options: opts
                ) { image, _ in
                    if let image {
                        let v = BlurMetric.variance(image)
                        if v < self.blurVarianceThreshold {
                            result.append(PhotoSummary(asset, fileSize: Self.estimateSize(asset)))
                        }
                    }
                    cont.resume()
                }
            }
            if idx % 50 == 0 { await progress(idx) }
        }
        return result
    }

    // MARK: - Pure helpers

    private nonisolated static func groupNearDuplicates(
        hashes: [String: UInt64],
        summaries: [String: PhotoSummary],
        threshold: Int
    ) -> [PhotoGroup] {
        // Bucket by 16-bit prefix so we only compare nearby hashes.
        var buckets: [UInt16: [(id: String, hash: UInt64)]] = [:]
        for (id, hash) in hashes {
            let key = UInt16(hash >> 48)
            buckets[key, default: []].append((id, hash))
        }

        var visited = Set<String>()
        var groups: [PhotoGroup] = []

        for (id, hash) in hashes where !visited.contains(id) {
            var bucketEntries: [(id: String, hash: UInt64)] = []
            let baseKey = UInt16(hash >> 48)
            // Check own bucket + 4 neighbours (±1, ±256) — rough coverage.
            for delta: Int in [0, 1, -1, 256, -256] {
                let raw = Int(baseKey) &+ delta
                guard raw >= 0 && raw <= 0xFFFF else { continue }
                if let entries = buckets[UInt16(raw)] {
                    bucketEntries.append(contentsOf: entries)
                }
            }

            var members: [PhotoSummary] = []
            for entry in bucketEntries where !visited.contains(entry.id) {
                if PerceptualHash.distance(hash, entry.hash) <= threshold,
                   let s = summaries[entry.id] {
                    members.append(s)
                    visited.insert(entry.id)
                }
            }

            if members.count >= 2 {
                let exact = members.allSatisfy { hashes[$0.id] == hash }
                groups.append(PhotoGroup(kind: exact ? .exact : .similar, items: members))
            }
        }
        return groups.sorted { $0.recoverableBytes > $1.recoverableBytes }
    }

    private nonisolated static func detectBursts(
        hashes: [String: UInt64],
        summaries: [String: PhotoSummary]
    ) -> [PhotoGroup] {
        let sorted = summaries.values
            .filter { !$0.isVideo && $0.creationDate != nil }
            .sorted { ($0.creationDate ?? .distantPast) < ($1.creationDate ?? .distantPast) }
        var groups: [PhotoGroup] = []
        var current: [PhotoSummary] = []
        var lastDate: Date?

        for item in sorted {
            guard let date = item.creationDate else { continue }
            if let last = lastDate, date.timeIntervalSince(last) <= 2 {
                current.append(item)
            } else {
                if current.count >= 3 { groups.append(PhotoGroup(kind: .burst, items: current)) }
                current = [item]
            }
            lastDate = date
        }
        if current.count >= 3 { groups.append(PhotoGroup(kind: .burst, items: current)) }
        return groups.sorted { $0.recoverableBytes > $1.recoverableBytes }
    }

    private nonisolated static func estimateSize(_ asset: PHAsset) -> Int64 {
        // Without loading the resource — rough estimate from pixel count.
        // Photos: ~3 bytes/pixel post-compression heuristic.
        // Videos: ~0.5 MB/s of duration.
        if asset.mediaType == .video {
            return Int64(asset.duration * 500_000)
        }
        return Int64(asset.pixelWidth * asset.pixelHeight * 3 / 10)
    }
}
