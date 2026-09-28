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

    private var displayedItems: [StorageItem] {
        guard let analysis = model.analysis else { return [] }
        let threshold = Int64(minimumSizeMB * 1_024 * 1_024)
        return analysis.items.filter { $0.size >= threshold && (selectedCategory == nil || $0.category == selectedCategory) }.sorted { $0.size > $1.size }
    }
    private var selectedItems: [StorageItem] { displayedItems.filter { selection.selected.contains($0.id) } }
    private var selectedBytes: Int64 { selectedItems.reduce(0) { $0 + $1.size } }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.zentraBackground, Color.zentraBackground, Color.zentraAccent.opacity(0.045)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if model.state == .scanning { progressCard }
                    if let analysis = model.analysis {
                        overview(analysis)
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

    private var progressCard: some View {
        ZentraCard { HStack(spacing: 13) {
            ProgressView().controlSize(.small)
            VStack(alignment: .leading, spacing: 4) {
                Text("storage.scanning").zentraFont(12, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                Text("\(model.fileCount) · \(ByteCountFormatter.string(fromByteCount: model.scannedBytes, countStyle: .file))").zentraFont(10.5).foregroundStyle(Color.zentraTextTertiary)
                if let url = model.currentURL { Text(url.lastPathComponent).lineLimit(1).zentraFont(9.5).foregroundStyle(Color.zentraTextTertiary) }
            }; Spacer()
        }}
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
            HStack {
                Text("storage.minimumSize").zentraFont(10).foregroundStyle(Color.zentraTextTertiary)
                Text("≥ \(Int(minimumSizeMB)) MB").zentraFont(10, weight: .semibold).foregroundStyle(Color.zentraTextSecondary)
                Slider(value: $minimumSizeMB, in: 50...1000, step: 50).frame(maxWidth: 220)
                Spacer()
                Text(String(format: NSLocalizedString("storage.results.count", comment: ""), displayedItems.count)).zentraFont(10).foregroundStyle(Color.zentraTextTertiary)
            }
            if displayedItems.isEmpty { Text("storage.noLargeFiles").zentraFont(11).foregroundStyle(Color.zentraTextTertiary).padding(.vertical, 18) }
            else if displayMode == .visual {
                StorageBubbleMap(items: displayedItems, selected: selection.selected, onToggle: selection.toggle, onReveal: { selection.reveal([$0.url]) }, onOpen: { selection.open($0.url) }, onTrash: { requestTrash([$0]) })
            } else {
                LazyVStack(spacing: 8) { ForEach(displayedItems.prefix(300)) { item in fileRow(item) } }
            }
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
        case .archives: "storage.category.archives"; case .applications: "storage.category.applications"; case .developer: "storage.category.developer"; case .other: "storage.category.other"
        }
    }
    var icon: String {
        switch self {
        case .documents: "doc.text"; case .images: "photo"; case .video: "film"; case .audio: "waveform"
        case .archives: "archivebox"; case .applications: "app"; case .developer: "hammer"; case .other: "doc"
        }
    }
}
