import Photos
import SwiftUI

struct GroupDetailView: View {
    let group: PhotoGroup

    /// Items in the group that are still present (i.e., not already deleted).
    @State private var visibleItems: [PhotoSummary]
    @State private var selectedIDs: Set<String>
    @State private var isDeleting = false
    @State private var errorMessage: String?

    init(group: PhotoGroup) {
        self.group = group
        let items = group.items
        _visibleItems = State(initialValue: items)
        // Default: pre-select all except the largest (keep the highest-quality copy).
        let keeper = items.max(by: { $0.estimatedFileSize < $1.estimatedFileSize })?.id
        _selectedIDs = State(initialValue: Set(items.compactMap { $0.id == keeper ? nil : $0.id }))
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 10)], spacing: 10) {
                ForEach(visibleItems) { item in
                    PhotoTile(item: item, selected: selectedIDs.contains(item.id))
                        .onTapGesture {
                            toggle(item.id)
                        }
                }
            }
            .padding()
        }
        .navigationTitle(Text("\(visibleItems.count) items"))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            deleteBar
        }
        .alert("Couldn't delete", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var deleteBar: some View {
        let selectedBytes = visibleItems
            .filter { selectedIDs.contains($0.id) }
            .reduce(Int64(0)) { $0 + $1.estimatedFileSize }
        return HStack {
            VStack(alignment: .leading) {
                Text("\(selectedIDs.count) selected")
                    .font(.callout.weight(.semibold))
                Text(ByteCountFormatter.string(fromByteCount: selectedBytes, countStyle: .file))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(role: .destructive) {
                Task { await delete() }
            } label: {
                if isDeleting {
                    ProgressView().controlSize(.small)
                } else {
                    Text("Delete")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
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
        let idsToDelete = Array(selectedIDs)
        guard !idsToDelete.isEmpty else { return }
        isDeleting = true
        defer { isDeleting = false }

        let fetch = PHAsset.fetchAssets(withLocalIdentifiers: idsToDelete, options: nil)
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(fetch)
            }
            visibleItems.removeAll { idsToDelete.contains($0.id) }
            selectedIDs.removeAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct PhotoTile: View {
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
