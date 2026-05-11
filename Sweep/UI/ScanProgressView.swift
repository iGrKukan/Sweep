import SwiftUI

struct ScanProgressView: View {
    let progress: Double
    let stage: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "wand.and.stars")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse)

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.accentColor)
                .padding(.horizontal, 32)

            Text(stage)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("\(Int(progress * 100))%")
                .font(.title3.weight(.semibold))
                .monospacedDigit()

            Spacer()
        }
    }
}

#Preview {
    ScanProgressView(progress: 0.42, stage: "Hashing photos… 1240/2900")
}
