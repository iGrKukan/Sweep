import SwiftUI

struct HomeView: View {
    let report: ScanReport
    let onRescan: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    SummaryHeader(report: report)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    NavigationLink {
                        GroupListView(title: "Duplicates", groups: report.duplicates)
                    } label: {
                        CategoryRow(
                            icon: "square.on.square",
                            title: "Duplicates",
                            count: report.duplicates.reduce(0) { $0 + $1.items.count },
                            bytes: report.duplicates.reduce(0) { $0 + $1.recoverableBytes }
                        )
                    }

                    NavigationLink {
                        PhotoListView(title: "Screenshots", items: report.screenshots)
                    } label: {
                        CategoryRow(
                            icon: "camera.viewfinder",
                            title: "Screenshots",
                            count: report.screenshots.count,
                            bytes: report.screenshots.reduce(0) { $0 + $1.estimatedFileSize }
                        )
                    }

                    NavigationLink {
                        PhotoListView(title: "Blurry", items: report.blurry)
                    } label: {
                        CategoryRow(
                            icon: "drop.fill",
                            title: "Blurry",
                            count: report.blurry.count,
                            bytes: report.blurry.reduce(0) { $0 + $1.estimatedFileSize }
                        )
                    }

                    NavigationLink {
                        GroupListView(title: "Bursts", groups: report.bursts)
                    } label: {
                        CategoryRow(
                            icon: "rectangle.stack",
                            title: "Bursts",
                            count: report.bursts.reduce(0) { $0 + $1.items.count },
                            bytes: report.bursts.reduce(0) { $0 + $1.recoverableBytes }
                        )
                    }

                    NavigationLink {
                        PhotoListView(title: "Large items", items: report.largeMedia)
                    } label: {
                        CategoryRow(
                            icon: "arrow.up.right.and.arrow.down.left.rectangle",
                            title: "Large items",
                            count: report.largeMedia.count,
                            bytes: report.largeMedia.reduce(0) { $0 + $1.estimatedFileSize }
                        )
                    }
                }

                Section {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .navigationTitle("Sweep")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Rescan", systemImage: "arrow.clockwise", action: onRescan)
                }
            }
        }
    }
}

private struct SummaryHeader: View {
    let report: ScanReport

    var body: some View {
        VStack(spacing: 6) {
            Text("Potential recovery")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(ByteCountFormatter.string(fromByteCount: report.recoverableBytes, countStyle: .file))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.tint)
            Text("Scanned \(report.totalLibraryCount) items")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

private struct CategoryRow: View {
    let icon: String
    let title: LocalizedStringKey
    let count: Int
    let bytes: Int64

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 28, height: 28)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(count)")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}
