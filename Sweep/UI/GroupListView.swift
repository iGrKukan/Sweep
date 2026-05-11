import SwiftUI

struct GroupListView: View {
    let title: LocalizedStringKey
    let groups: [PhotoGroup]

    var body: some View {
        Group {
            if groups.isEmpty {
                ContentUnavailableView("Nothing found", systemImage: "checkmark.seal")
            } else {
                List(groups) { group in
                    NavigationLink {
                        GroupDetailView(group: group)
                    } label: {
                        GroupRow(group: group)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct GroupRow: View {
    let group: PhotoGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(group.items.prefix(8)) { item in
                        AssetThumbnail(id: item.id, side: 80)
                    }
                    if group.items.count > 8 {
                        Text("+\(group.items.count - 8)")
                            .frame(width: 80, height: 80)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
            }
            HStack {
                Label(group.kind.label, systemImage: group.kind.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(group.items.count) · \(ByteCountFormatter.string(fromByteCount: group.recoverableBytes, countStyle: .file))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private extension PhotoGroup.Kind {
    var label: LocalizedStringKey {
        switch self {
        case .exact: return "Exact match"
        case .similar: return "Similar"
        case .burst: return "Burst"
        }
    }
    var icon: String {
        switch self {
        case .exact: return "equal.circle"
        case .similar: return "circle.dotted"
        case .burst: return "rectangle.stack"
        }
    }
}
