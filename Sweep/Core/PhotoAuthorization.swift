import Foundation
import Observation
import Photos
import UIKit

@MainActor
@Observable
final class PhotoAuthorization {
    enum Status: Equatable {
        case notDetermined
        case denied
        case restricted
        case limited
        case authorized
    }

    private(set) var status: Status

    init() {
        status = Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    func refresh() {
        status = Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    func request() async {
        let raw = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        status = Self.map(raw)
    }

    /// Opens iOS Settings → Sweep so the user can grant full access manually.
    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private static func map(_ raw: PHAuthorizationStatus) -> Status {
        switch raw {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .restricted: return .restricted
        case .limited: return .limited
        case .authorized: return .authorized
        @unknown default: return .denied
        }
    }
}
