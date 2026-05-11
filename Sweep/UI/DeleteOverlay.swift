import SwiftUI

/// Full-screen translucent indicator shown while a PhotoKit delete is in
/// flight. iOS first shows its own confirm sheet on top of this; once the
/// user accepts, the system spinner takes a beat to actually purge the
/// assets — that's the time our overlay covers.
struct DeleteOverlay: View {
    let count: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                Text("Deleting \(count) items…")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white)
            }
            .padding(28)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .transition(.opacity)
    }
}
