import SwiftUI
import AppKit

struct StorageView: View {
    enum DisplayMode: String, CaseIterable { case visual, list }

    @StateObject private var model = StorageAnalysisModel()
    @StateObject private var selection = StorageSelectionModel()
    @State private var selectedCategory: StorageCategory?
    @State private var minimumSizeMB: Double = 100
    @State private var displayMode: DisplayMode = .visual
    @State private var pendingTrash: [StorageItem] = []
    @State private var showTrashConfirmation = false
    @State private var visualPath: [URL] = []
    @State private var sortMode: StorageSortMode = .size
    @State private var searchText = ""

    private var displayedItems: [StorageItem] {
        guard let analysis = model.analysis else { return [] }
        let threshold = Int64(minimumSizeMB * 1_024 * 1_024)
        let filtered = analysis.items.filter {
            $0.size >= threshold &&
            (selectedCategory == nil || $0.category == selectedCategory) &&
            (searchText.isEmpty || $0.url.lastPathComponent.localizedCaseInsensitiveContains(searchText))
        }
        switch sortMode {
        case .size: return filtered.sorted { $0.size > $1.size }
        case .name: return filtered.sorted { $0.url.lastPathComponent.localizedCaseInsensitiveCompare($1.url.lastPathComponent) == .orderedAscending }
        case .modified: return filtered.sorted { ($0.modifiedAt ?? .distantPast) > ($1.modifiedAt ?? .distantPast) }
        }
    }
    private var visualDirectory: URL {
        visualPath.last ?? FileManager.default.homeDirectoryForCurrentUser
    }
    private var visualNodes: [StorageNode] {
        guard let analysis = model.analysis else { return [] }
        return StorageTreeBuilder().children(of: visualDirectory, from: analysis.items)
    }
    private var selectedItems: [StorageItem] { displayedItems.filter { selection.selected.contains($0.id) } }
    private var selectedBytes: Int64 { selectedItems.reduce(0) { $0 + $1.size } }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.zentraBackground, Color.zentraBackground, Color.zentraAccent.opacity(0.045)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if model.state == .scanning { StorageScanChart(files: model.fileCount, bytes: model.scannedBytes, currentURL: model.currentURL) }
                    if let analysis = model.analysis {
                        overview(analysis)
                        fullDiskNotice(analysis)
                        categoryGrid(analysis)
                        explorer
                    } else if model.state != .scanning { emptyState }
                }.frame(maxWidth: 1040).frame(maxWidth: .infinity).padding(36)
            }
            if !selection.selected.isEmpty { selectionBar }
        }
        .alert("storage.trash.confirm.title", isPresented: $showTrashConfirmation) {
            Button("storage.action.cancel", role: .cancel) { pendingTrash = [] }
            Button("storage.action.trash", role: .destructive) { performTrash() }
        } message: {
            Text(String(format: NSLocalizedString("storage.trash.confirm.detail", comment: ""), pendingTrash.count))
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 7) {
                Text("storage.title").zentraFont(30, weight: .bold).foregroundStyle(Color.zentraTextPrimary)
                Text("storage.subtitle").zentraFont(13).foregroundStyle(Color.zentraTextSecondary)
            }
            Spacer()
            if model.state == .scanning {
                Button("scan.cancel") { model.cancel() }.buttonStyle(.plain).foregroundStyle(Color.zentraTextSecondary)
            } else { ZentraPrimaryButton("storage.scan", action: model.start) }
        }
    }

    private func overview(_ analysis: StorageAnalysis) -> some View {
        HStack(spacing: 12) {
            metric("storage.analyzed", ByteCountFormatter.string(fromByteCount: analysis.totalBytes, countStyle: .file), "internaldrive")
            metric("storage.files", "\(analysis.items.count)", "doc.on.doc")
            metric("storage.largeFiles", "\(analysis.largeFiles.count)", "arrow.up.right.square")
        }
    }

    private func metric(_ title: LocalizedStringKey, _ value: String, _ icon: String) -> some View {
        ZentraCard { VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(Color.zentraAccent)
            Text(value).zentraFont(18, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
            Text(title).zentraFont(10).foregroundStyle(Color.zentraTextTertiary)
        }.frame(maxWidth: .infinity, alignment: .leading) }
    }

    private func fullDiskNotice(_ analysis: StorageAnalysis) -> some View {
        HStack(spacing: 9) {
            Image(systemName: analysis.skippedItems > 0 ? "lock.shield" : "checkmark.shield")
                .foregroundStyle(analysis.skippedItems > 0 ? Color.zentraAccent : Color.zentraTextSecondary)
            Text("storage.fullDisk.note").zentraFont(9.5).foregroundStyle(Color.zentraTextTertiary)
            Spacer()
            if analysis.skippedItems > 0 {
                Text("\(analysis.skippedItems)")
                    .zentraFont(9, weight: .semibold).foregroundStyle(Color.zentraAccent)
            }
        }.padding(10).background(RoundedRectangle(cornerRadius: 10).fill(Color.zentraSurface))
    }

    private func categoryGrid(_ analysis: StorageAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("storage.categories").zentraFont(15, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                ForEach(StorageCategory.allCases, id: \.self) { category in
                    Button { selectedCategory = selectedCategory == category ? nil : category; selection.clear() } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(category.titleKey).zentraFont(11, weight: .semibold)
                            Text(ByteCountFormatter.string(fromByteCount: analysis.categoryBytes[category, default: 0], countStyle: .file)).zentraFont(10)
                        }.foregroundStyle(selectedCategory == category ? Color.zentraAccent : Color.zentraTextSecondary)
                         .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                         .background(RoundedRectangle(cornerRadius: 12).fill(selectedCategory == category ? Color.zentraAccent.opacity(0.09) : Color.zentraSurface))
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private var explorer: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("storage.explorer").zentraFont(15, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                Spacer()
                Picker("", selection: $displayMode) {
                    Label("storage.view.visual", systemImage: "circle.hexagongrid").tag(DisplayMode.visual)
                    Label("storage.view.list", systemImage: "list.bullet").tag(DisplayMode.list)
                }.pickerStyle(.segmented).frame(width: 230)
            }
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Color.zentraTextTertiary)
                    TextField("storage.search", text: $searchText).textFieldStyle(.plain).zentraFont(10.5)
                }.padding(.horizontal, 10).frame(width: 210, height: 30).background(RoundedRectangle(cornerRadius: 9).fill(Color.zentraSurface))
                Picker("", selection: $sortMode) {
                    Text("storage.sort.size").tag(StorageSortMode.size)
                    Text("storage.sort.name").tag(StorageSortMode.name)
                    Text("storage.sort.modified").tag(StorageSortMode.modified)
                }.frame(width: 130)
                Text("storage.minimumSize").zentraFont(10).foregroundStyle(Color.zentraTextTertiary)
                Text("≥ \(Int(minimumSizeMB)) MB").zentraFont(10, weight: .semibold).foregroundStyle(Color.zentraTextSecondary)
                Slider(value: $minimumSizeMB, in: 50...1000, step: 50).frame(maxWidth: 220)
                Spacer()
                Text(String(format: NSLocalizedString("storage.results.count", comment: ""), displayedItems.count)).zentraFont(10).foregroundStyle(Color.zentraTextTertiary)
            }
            if displayedItems.isEmpty { Text("storage.noLargeFiles").zentraFont(11).foregroundStyle(Color.zentraTextTertiary).padding(.vertical, 18) }
            else if displayMode == .visual {
                visualExplorer
            } else {
                HStack {
                    Button("storage.selection.selectVisible") {
                        selection.select(Array(displayedItems.prefix(300).map(\.id)))
                    }.buttonStyle(.plain).zentraFont(10).foregroundStyle(Color.zentraAccent)
                    Spacer()
                }
                LazyVStack(spacing: 8) { ForEach(displayedItems.prefix(300)) { item in fileRow(item) } }
            }
        }
    }

    private var visualExplorer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "internaldrive.fill").foregroundStyle(Color.zentraAccent)
                Button { visualPath.removeAll() } label: { Image(systemName: "house.fill") }.buttonStyle(.plain).foregroundStyle(Color.zentraTextSecondary)
                ForEach(Array(visualPath.enumerated()), id: \.offset) { index, url in
                    Image(systemName: "chevron.right").font(.system(size: 8)).foregroundStyle(Color.zentraTextTertiary)
                    Button(url.lastPathComponent) { visualPath = Array(visualPath.prefix(index + 1)) }.buttonStyle(.plain).zentraFont(9.5).foregroundStyle(index == visualPath.count - 1 ? Color.zentraAccent : Color.zentraTextSecondary)
                }
                Spacer()
                Text(ByteCountFormatter.string(fromByteCount: visualNodes.reduce(Int64(0)) { $0 + $1.totalBytes }, countStyle: .file))
                    .zentraFont(9.5, weight: .semibold).foregroundStyle(Color.zentraTextTertiary)
                if !visualPath.isEmpty { Button("storage.visual.up") { visualPath.removeLast() }.buttonStyle(.plain).zentraFont(10).foregroundStyle(Color.zentraTextSecondary) }
            }
            StorageBubbleMap(
                nodes: visualNodes,
                selected: selection.selected,
                onSelect: { node in
                    guard let item = model.analysis?.items.first(where: { $0.url == node.url }) else { return }
                    selection.toggle(item)
                },
                onOpenDirectory: { visualPath.append($0.url) },
                onReveal: { selection.reveal([$0.url]) },
                onOpen: { selection.open($0.url) },
                onTrash: { node in
                    guard let item = model.analysis?.items.first(where: { $0.url == node.url }) else { return }
                    requestTrash([item])
                }
            )
        }
    }

    private func fileRow(_ item: StorageItem) -> some View {
        let checked = selection.selected.contains(item.id)
        return HStack(spacing: 12) {
            Button { selection.toggle(item) } label: { Image(systemName: checked ? "checkmark.circle.fill" : "circle").foregroundStyle(checked ? Color.zentraAccent : Color.zentraTextTertiary) }.buttonStyle(.plain)
            Image(systemName: item.category.icon).foregroundStyle(Color.zentraAccent).frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.url.lastPathComponent).lineLimit(1).zentraFont(11.5, weight: .medium).foregroundStyle(Color.zentraTextPrimary)
                Text(item.url.deletingLastPathComponent().path).lineLimit(1).zentraFont(9.5).foregroundStyle(Color.zentraTextTertiary)
            }
            Spacer()
            Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file)).zentraFont(10.5).foregroundStyle(Color.zentraTextSecondary)
        }.padding(11).background(RoundedRectangle(cornerRadius: 11).fill(checked ? Color.zentraAccent.opacity(0.07) : Color.zentraSurface))
         .contentShape(Rectangle()).onTapGesture { selection.toggle(item) }
         .contextMenu {
             Button("storage.action.open") { selection.open(item.url) }
             Button("storage.action.reveal") { selection.reveal([item.url]) }
             Divider()
             Button("storage.action.trash", role: .destructive) { requestTrash([item]) }
         }
    }

    private var selectionBar: some View {
        VStack { Spacer(); HStack(spacing: 14) {
            Text(String(format: NSLocalizedString("storage.selected.summary", comment: ""), selection.selected.count, ByteCountFormatter.string(fromByteCount: selectedBytes, countStyle: .file))).zentraFont(11, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
            Spacer()
            Button("storage.action.reveal") { selection.reveal(selectedItems.map(\.url)) }.buttonStyle(.plain).foregroundStyle(Color.zentraTextSecondary)
            Button("storage.selection.clear") { selection.clear() }.buttonStyle(.plain).foregroundStyle(Color.zentraTextSecondary)
            Button("storage.action.trash", role: .destructive) { requestTrash(selectedItems) }.disabled(selection.isDeleting)
        }.padding(.horizontal, 18).frame(height: 54).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 16)).padding(20) }
    }

    private var emptyState: some View {
        ZentraCard { VStack(spacing: 12) {
            Image(systemName: "internaldrive").font(.system(size: 28)).foregroundStyle(Color.zentraAccent)
            Text("storage.empty.title").zentraFont(14, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
            Text("storage.empty.detail").zentraFont(11).foregroundStyle(Color.zentraTextSecondary)
        }.frame(maxWidth: .infinity).padding(.vertical, 24) }
    }

    private func requestTrash(_ items: [StorageItem]) { guard !items.isEmpty else { return }; pendingTrash = items; showTrashConfirmation = true }
    private func performTrash() { let values = pendingTrash; pendingTrash = []; selection.moveToTrash(values) { model.start() } }
}

extension StorageCategory {
    var titleKey: LocalizedStringKey {
        switch self {
        case .documents: "storage.category.documents"; case .images: "storage.category.images"; case .video: "storage.category.video"; case .audio: "storage.category.audio"
        case .archives: "storage.category.archives"; case .applications: "storage.category.applications"; case .developer: "storage.category.developer"; case .system: "storage.category.system"; case .library: "storage.category.library"; case .other: "storage.category.other"
        }
    }
    var icon: String {
        switch self {
        case .documents: "doc.text"; case .images: "photo"; case .video: "film"; case .audio: "waveform"
        case .archives: "archivebox"; case .applications: "app"; case .developer: "hammer"; case .system: "gearshape.2"; case .library: "books.vertical"; case .other: "doc"
        }
    }
}


private enum StorageSortMode: String, CaseIterable {
    case size, name, modified
}
