import SwiftUI

struct RootView: View {
    @Environment(PhotoAuthorization.self) private var auth
    @Environment(ScanCoordinator.self) private var scan
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch auth.status {
            case .authorized, .limited:
                scanFlow
            case .notDetermined, .denied, .restricted:
                PermissionGateView()
            }
        }
        .animation(.default, value: auth.status)
        .onChange(of: scenePhase) { _, new in
            if new == .active { auth.refresh() }
        }
    }

    @ViewBuilder
    private var scanFlow: some View {
        switch scan.state {
        case .idle:
            ScanProgressView(progress: 0, stage: "Preparing…")
                .onAppear { scan.start() }
        case let .scanning(progress, stage):
            ScanProgressView(progress: progress, stage: stage)
        case let .complete(report):
            HomeView(report: report) { scan.start() }
        case let .failed(message):
            ContentUnavailableView("Scan failed", systemImage: "exclamationmark.triangle", description: Text(message))
        }
    }
}

