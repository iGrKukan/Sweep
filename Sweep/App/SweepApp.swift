import SwiftUI

@main
struct SweepApp: App {
    @State private var auth = PhotoAuthorization()
    @State private var scan = ScanCoordinator()
    @State private var purchases = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(scan)
                .environment(purchases)
        }
    }
}
