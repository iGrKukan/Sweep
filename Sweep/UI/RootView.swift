import SwiftUI

struct RootView: View {
    @Environment(PhotoAuthorization.self) private var auth
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch auth.status {
            case .authorized, .limited:
                MainTabView()
            case .notDetermined, .denied, .restricted:
                PermissionGateView()
            }
        }
        .animation(.default, value: auth.status)
        .onChange(of: scenePhase) { _, new in
            if new == .active { auth.refresh() }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            PlaceholderTab(title: "Duplicates", icon: "square.on.square")
            PlaceholderTab(title: "Screenshots", icon: "camera.viewfinder")
            PlaceholderTab(title: "Blurry", icon: "drop.fill")
            PlaceholderTab(title: "Large", icon: "arrow.up.right.and.arrow.down.left.rectangle")
            PlaceholderTab(title: "Settings", icon: "gearshape")
        }
    }
}

private struct PlaceholderTab: View {
    let title: LocalizedStringKey
    let icon: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(title, systemImage: icon, description: Text("Coming in v1.0"))
                .navigationTitle(title)
        }
        .tabItem { Label(title, systemImage: icon) }
    }
}

#Preview { RootView() }
