import Photos

/// Wraps PHPhotoLibrary.performChanges in a completion-handler bridge.
///
/// `nonisolated` keeps this off the MainActor, so the change-block executes
/// outside of Swift 6 isolation runtime checks that fail on iOS 26 when the
/// async version is called from a MainActor View.
enum AssetDeleter {
    /// Returns `true` if the assets were actually deleted, `false` if iOS
    /// showed the system confirm and the user tapped Cancel. Throws only for
    /// real PhotoKit errors (revoked permission, network failure, etc.).
    static func deleteAssets(localIdentifiers: [String]) async throws -> Bool {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Bool, Error>) in
            PHPhotoLibrary.shared().performChanges({
                let fetch = PHAsset.fetchAssets(withLocalIdentifiers: localIdentifiers, options: nil)
                PHAssetChangeRequest.deleteAssets(fetch)
            }, completionHandler: { success, error in
                print("[AssetDeleter] count=\(localIdentifiers.count) success=\(success) error=\(String(describing: error))")
                if let error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume(returning: success)
                }
            })
        }
    }
}
