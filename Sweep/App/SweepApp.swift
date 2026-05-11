import SwiftUI

@main
struct SweepApp: App {
    @State private var auth = PhotoAuthorization()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
        }
    }
}
