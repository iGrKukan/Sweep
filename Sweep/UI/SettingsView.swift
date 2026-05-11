import SwiftUI

struct SettingsView: View {
    @Environment(PurchaseManager.self) private var purchases
    @State private var showingPaywall = false

    var body: some View {
        List {
            Section("Pro") {
                if purchases.isPro {
                    Label("Sweep Pro unlocked", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.tint)
                } else {
                    let remaining = FreeQuota.shared.remainingThisWindow()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Free tier: \(remaining) deletions remaining this week.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Button {
                            showingPaywall = true
                        } label: {
                            Label("Upgrade to Sweep Pro", systemImage: "sparkles")
                        }
                    }
                }
            }

            Section("About") {
                LabeledContent("Version", value: appVersion)
                Link("Privacy Policy", destination: URL(string: "https://igrkukan.github.io/Sweep/privacy.html")!)
                Link("Support", destination: URL(string: "mailto:timbelwood@gmail.com")!)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }
}
