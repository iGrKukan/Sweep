import Photos
import SwiftUI

struct PhotoListView: View {
    let title: LocalizedStringKey
    let items: [PhotoSummary]

    @Environment(PurchaseManager.self) private var purchases
    @Environment(ScanCoordinator.self) private var scan
    @State private var visibleItems: [PhotoSummary]
    @State private var selectedIDs: Set<String> = []
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var showingPaywall = false

    init(title: LocalizedStringKey, items: [PhotoSummary]) {
        self.title = title
        self.items = items
        _visibleItems = State(initialValue: items)
    }

    var body: some View {
        Group {
            if visibleItems.isEmpty {
                ContentUnavailableView("Nothing found", systemImage: "checkmark.seal")
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                        ForEach(visibleItems) { item in
                            Tile(item: item, selected: selectedIDs.contains(item.id))
                                .onTapGesture { toggle(item.id) }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !visibleItems.isEmpty { deleteBar }
        }
        .alert("Couldn't delete", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
    }

    private var deleteBar: some View {
        let bytes = visibleItems
            .filter { selectedIDs.contains($0.id) }
            .reduce(Int64(0)) { $0 + $1.estimatedFileSize }
        return HStack {
            Button(selectedIDs.count == visibleItems.count ? "Deselect all" : "Select all") {
                if selectedIDs.count == visibleItems.count {
                    selectedIDs.removeAll()
                } else {
                    selectedIDs = Set(visibleItems.map { $0.id })
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(selectedIDs.count) · \(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Button(role: .destructive) {
                Task { await delete() }
            } label: {
                if isDeleting {
                    ProgressView().controlSize(.small)
                } else {
                    Text("Delete")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedIDs.isEmpty || isDeleting)
        }
        .padding()
        .background(.bar)
    }

    private func toggle(_ id: String) {
        if selectedIDs.contains(id) { selectedIDs.remove(id) } else { selectedIDs.insert(id) }
    }

    private func delete() async {
        let ids = Array(selectedIDs)
        guard !ids.isEmpty else { return }
        if !purchases.isPro && !FreeQuota.shared.canDelete(ids.count) {
            showingPaywall = true
            return
        }
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await AssetDeleter.deleteAssets(localIdentifiers: ids)
            if !purchases.isPro { FreeQuota.shared.record(ids.count) }
            visibleItems.removeAll { ids.contains($0.id) }
            selectedIDs.removeAll()
            scan.acknowledgeDeletions(Set(ids))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct Tile: View {
    let item: PhotoSummary
    let selected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AssetThumbnail(id: item.id, side: 110)
                .opacity(selected ? 0.7 : 1.0)
                .overlay {
                    if selected {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(.tint, lineWidth: 3)
                    }
                }
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selected ? .white : .white.opacity(0.8))
                .background(.black.opacity(0.4), in: .circle)
                .padding(6)
        }
    }
}
