import Photos
import SwiftUI
import UIKit

/// Loads PHAsset thumbnails by `localIdentifier`, with an in-memory NSCache.
/// Loads happen on a serial background queue so SwiftUI rows scroll without jank.
@MainActor
final class ThumbnailLoader {
    static let shared = ThumbnailLoader()

    private let cache = NSCache<NSString, UIImage>()
    private let manager = PHCachingImageManager()
    private let options: PHImageRequestOptions = {
        let o = PHImageRequestOptions()
        o.deliveryMode = .opportunistic
        o.resizeMode = .fast
        o.isNetworkAccessAllowed = true
        return o
    }()

    private init() {
        cache.countLimit = 800
    }

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
            let scale = await UIScreen.main.scale
            let pixelSide = side * scale
            image = await ThumbnailLoader.shared.image(
                for: id,
                targetSize: CGSize(width: pixelSide, height: pixelSide)
            )
        }
    }
}
