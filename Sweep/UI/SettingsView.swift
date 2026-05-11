import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section("About") {
                LabeledContent("Version", value: appVersion)
                Link("Privacy Policy", destination: URL(string: "https://igrkukan.github.io/Sweep/privacy.html")!)
                Link("Support", destination: URL(string: "mailto:timbelwood@gmail.com")!)
            }

            Section("Pro") {
                Text("Coming soon: unlock unlimited deletion + smart suggestions for $9.99 (one-time).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }
}
