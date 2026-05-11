import Foundation
import Photos

struct PhotoSummary: Identifiable, Hashable, Sendable {
    let id: String
    let creationDate: Date?
    let pixelWidth: Int
    let pixelHeight: Int
    let mediaType: Int
    let mediaSubtypeRaw: UInt
    let duration: TimeInterval
    let estimatedFileSize: Int64

    init(_ asset: PHAsset, fileSize: Int64) {
        id = asset.localIdentifier
        creationDate = asset.creationDate
        pixelWidth = asset.pixelWidth
        pixelHeight = asset.pixelHeight
        mediaType = asset.mediaType.rawValue
        mediaSubtypeRaw = asset.mediaSubtypes.rawValue
        duration = asset.duration
        estimatedFileSize = fileSize
    }

    var isVideo: Bool { mediaType == PHAssetMediaType.video.rawValue }
    var isScreenshot: Bool {
        PHAssetMediaSubtype(rawValue: mediaSubtypeRaw).contains(.photoScreenshot)
    }
}

struct PhotoGroup: Identifiable, Sendable {
    enum Kind: String, Sendable { case exact, similar, burst }

    let id: UUID
    let kind: Kind
    let items: [PhotoSummary]

    init(kind: Kind, items: [PhotoSummary]) {
        self.id = UUID()
        self.kind = kind
        self.items = items
    }

    /// Recoverable bytes if user deletes all but the largest item in the group.
    var recoverableBytes: Int64 {
        guard let keep = items.max(by: { $0.estimatedFileSize < $1.estimatedFileSize }) else { return 0 }
        return items.reduce(0) { $0 + $1.estimatedFileSize } - keep.estimatedFileSize
    }
}

struct ScanReport: Sendable {
    let duplicates: [PhotoGroup]          // exact + similar
    let screenshots: [PhotoSummary]
    let blurry: [PhotoSummary]
    let bursts: [PhotoGroup]
    let largeMedia: [PhotoSummary]        // sorted desc by size, top N
    let totalLibraryCount: Int

    static let empty = ScanReport(
        duplicates: [],
        screenshots: [],
        blurry: [],
        bursts: [],
        largeMedia: [],
        totalLibraryCount: 0
    )

    var recoverableBytes: Int64 {
        let dups = duplicates.reduce(0) { $0 + $1.recoverableBytes }
        let burstsBytes = bursts.reduce(0) { $0 + $1.recoverableBytes }
        let blurryBytes = blurry.reduce(0) { $0 + $1.estimatedFileSize }
        let shotsBytes = screenshots.reduce(0) { $0 + $1.estimatedFileSize }
        return dups + burstsBytes + blurryBytes + shotsBytes
    }
}
