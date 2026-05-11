import SwiftUI

struct PermissionGateView: View {
    @Environment(PhotoAuthorization.self) private var auth

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "photo.stack.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            VStack(spacing: 12) {
                Text("Sweep needs full photo access")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(detailMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            VStack(spacing: 8) {
                bullet("All scanning happens on your iPhone — nothing is uploaded.")
                bullet("Sweep only suggests photos to delete. You confirm every action.")
                bullet("Full access lets us see duplicates across your entire library, not just a subset.")
            }
            .padding(.horizontal)

            Spacer()

            actionButton
                .padding(.horizontal)
                .padding(.bottom, 24)
        }
    }

    private var detailMessage: LocalizedStringKey {
        switch auth.status {
        case .notDetermined:
            return "Grant access so Sweep can find duplicates, blurry shots and old screenshots."
        case .limited:
            return "Sweep can only see the photos you picked. Switch to Full Access to scan everything."
        case .denied:
            return "Photo access is currently disabled. Open Settings → Sweep → Photos to enable it."
        case .restricted:
            return "Photo access is restricted on this device (Screen Time or a profile blocks it)."
        case .authorized:
            return ""
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch auth.status {
        case .notDetermined:
            Button {
                Task { await auth.request() }
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        case .limited, .denied:
            Button {
                auth.openSettings()
            } label: {
                Text("Open Settings")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        case .restricted:
            Text("Contact the device administrator to lift the restriction.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        case .authorized:
            EmptyView()
        }
    }

    private func bullet(_ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.tint)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    PermissionGateView()
        .environment(PhotoAuthorization())
}
