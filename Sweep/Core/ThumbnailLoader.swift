import Photos
import SwiftUI
import UIKit

/// Loads PHAsset thumbnails by `localIdentifier`, with an in-memory NSCache.
///
/// NSCache and PHCachingImageManager are both thread-safe, so the loader
/// itself is `Sendable` (not MainActor-isolated). This avoids actor hops
/// inside the request callback that PHImageManager invokes off the main thread.
final class ThumbnailLoader: @unchecked Sendable {
    static let shared = ThumbnailLoader()

    private let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        c.countLimit = 800
        return c
    }()
    private let manager = PHCachingImageManager()
    private let options: PHImageRequestOptions = {
        let o = PHImageRequestOptions()
        // `.opportunistic` fires the callback twice (placeholder, then final),
        // and CheckedContinuation traps on a second resume. `.fastFormat`
        // guarantees a single callback with a thumbnail-quality result.
        o.deliveryMode = .fastFormat
        o.resizeMode = .fast
        o.isNetworkAccessAllowed = true
        return o
    }()

    private init() {}

    func image(for id: String, targetSize: CGSize) async -> UIImage? {
        let key = "\(id)|\(Int(targetSize.width))x\(Int(targetSize.height))" as NSString
        if let hit = cache.object(forKey: key) { return hit }
        let fetch = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        guard let asset = fetch.firstObject else { return nil }

        return await withCheckedContinuation { cont in
            manager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                if let image { self.cache.setObject(image, forKey: key) }
                cont.resume(returning: image)
            }
        }
    }
}

struct AssetThumbnail: View {
    let id: String
    var side: CGFloat = 96

    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color(uiColor: .secondarySystemBackground)
                ProgressView().controlSize(.small)
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .task(id: id) {
            let pixelSide = side * displayScale
            image = await ThumbnailLoader.shared.image(
                for: id,
                targetSize: CGSize(width: pixelSide, height: pixelSide)
            )
        }
    }
}
