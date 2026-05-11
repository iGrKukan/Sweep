import SwiftUI

@main
struct SweepApp: App {
    @State private var auth = PhotoAuthorization()
    @State private var scan = ScanCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(scan)
        }
    }
}
