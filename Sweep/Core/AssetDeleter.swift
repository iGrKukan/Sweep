import Photos

/// Wraps PHPhotoLibrary.performChanges in a completion-handler bridge.
///
/// `nonisolated` keeps this off the MainActor, so the change-block executes
/// outside of Swift 6 isolation runtime checks that fail on iOS 26 when the
/// async version is called from a MainActor View.
enum AssetDeleter {
    static func deleteAssets(localIdentifiers: [String]) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                let fetch = PHAsset.fetchAssets(withLocalIdentifiers: localIdentifiers, options: nil)
                PHAssetChangeRequest.deleteAssets(fetch)
            }, completionHandler: { success, error in
                if let error {
                    cont.resume(throwing: error)
                } else if success {
                    cont.resume(returning: ())
                } else {
                    cont.resume(throwing: NSError(
                        domain: "Sweep.AssetDeleter",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Deletion cancelled or denied."]
                    ))
                }
            })
        }
    }
}
