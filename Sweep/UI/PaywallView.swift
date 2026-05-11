import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .padding(8)
                        .background(.regularMaterial, in: .circle)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Sweep Pro")
                .font(.largeTitle.weight(.bold))

            Text("One purchase. Yours forever.")
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 14) {
                feature(icon: "infinity", title: "Unlimited deletions", desc: "Free users delete up to 20 photos a week.")
                feature(icon: "wand.and.stars", title: "Smart suggestions", desc: "Sweep highlights bursts and screenshots older than 90 days.")
                feature(icon: "lock.shield", title: "Stays on device", desc: "Nothing is uploaded — ever.")
                feature(icon: "heart.fill", title: "Supports indie dev", desc: "No ads, no subscriptions, no tracking.")
            }
            .padding(.horizontal)

            Spacer(minLength: 0)

            buyButton
                .padding(.horizontal)

            Button("Restore purchases") {
                Task { await purchases.restore() }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding()
        .alert("Couldn't complete", isPresented: Binding(
            get: { purchases.lastError != nil },
            set: { if !$0 { purchases.lastError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchases.lastError ?? "")
        }
        .onChange(of: purchases.isPro) { _, new in
            if new { dismiss() }
        }
    }

    @ViewBuilder
    private var buyButton: some View {
        if let product = purchases.proProduct {
            Button {
                Task { _ = await purchases.buy() }
            } label: {
                HStack {
                    Text("Unlock for \(product.displayPrice)")
                        .font(.headline)
                    if purchases.isLoading {
                        ProgressView().controlSize(.small).tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(purchases.isLoading)
        } else {
            ProgressView().padding()
        }
    }

    private func feature(icon: String, title: LocalizedStringKey, desc: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 28)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout.weight(.semibold))
                Text(desc).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}
