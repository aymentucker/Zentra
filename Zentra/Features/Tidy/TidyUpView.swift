import SwiftUI
import AppKit

struct TidyUpView: View {
    @StateObject private var model = TidyModel()
    @State private var folder: URL?
    @State private var confirm = false

    var body: some View {
        ZStack {
            Color.zentraBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    if model.isScanning {
                        scanningCard
                    }

                    if let analysis = model.analysis, let folder {
                        summary(analysis, folder: folder)

                        ForEach(TidyCategory.allCases) { category in
                            let values = analysis.items.filter { $0.category == category }
                            if !values.isEmpty {
                                categorySection(category, items: values)
                            }
                        }

                        actionBar
                    } else if !model.isScanning {
                        emptyState
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 48)
                .padding(.vertical, 36)
            }
        }
        .alert("tidy.confirm.title", isPresented: $confirm) {
            Button("cleanup.cancel", role: .cancel) {}
            Button("tidy.organize") {
                if let folder {
                    model.organize(in: folder)
                }
            }
        } message: {
            Text("tidy.confirm.detail")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 7) {
                Text("tidy.title").zentraFont(30, weight: .bold)
                Text("tidy.subtitle")
                    .zentraFont(13)
                    .foregroundStyle(Color.zentraTextSecondary)
            }
            Spacer()
            ZentraPrimaryButton("tidy.choose") { chooseFolder() }
        }
    }

    private var scanningCard: some View {
        ZentraCard {
            HStack(spacing: 12) {
                ProgressView()
                Text("tidy.scanning").zentraFont(12, weight: .semibold)
                Spacer()
            }
        }
    }

    private func summary(_ analysis: TidyAnalysis, folder: URL) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "folder.fill").foregroundStyle(Color.zentraAccent)
            Text(folder.path)
                .lineLimit(1)
                .truncationMode(.middle)
                .zentraFont(10)
            Spacer()
            Text(ByteCountFormatter.string(fromByteCount: analysis.bytes, countStyle: .file))
                .zentraFont(11, weight: .semibold)
        }
    }

    private func categorySection(_ category: TidyCategory, items: [TidyItem]) -> some View {
        ZentraCard {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Image(systemName: icon(for: category)).foregroundStyle(Color.zentraAccent)
                    Text(LocalizedStringKey("tidy.category.\(category.rawValue)"))
                        .zentraFont(12, weight: .semibold)
                    Spacer()
                    Text("\(items.count)")
                        .zentraFont(9)
                        .foregroundStyle(Color.zentraTextTertiary)
                }

                ForEach(items.prefix(100)) { item in
                    HStack(spacing: 10) {
                        Button { model.toggle(item) } label: {
                            Image(systemName: model.selected.contains(item.url) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(Color.zentraAccent)
                        }
                        .buttonStyle(.plain)

                        Text(item.url.lastPathComponent)
                            .lineLimit(1)
                            .zentraFont(10)

                        Spacer()

                        Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                            .zentraFont(9)
                            .foregroundStyle(Color.zentraTextTertiary)
                    }
                }
            }
        }
    }

    private var actionBar: some View {
        HStack {
            Text(String(format: NSLocalizedString("tidy.selected", comment: ""), model.selected.count))
                .zentraFont(11, weight: .semibold)
            Spacer()
            Button("storage.selection.clear") { model.selected = [] }
                .buttonStyle(.plain)
            ZentraPrimaryButton("tidy.organize") { confirm = true }
        }
    }

    private var emptyState: some View {
        ZentraCard {
            VStack(spacing: 10) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.zentraAccent)
                Text("tidy.empty").zentraFont(14, weight: .semibold)
                Text("tidy.empty.detail")
                    .zentraFont(10)
                    .foregroundStyle(Color.zentraTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
    }

    private func icon(for category: TidyCategory) -> String {
        switch category {
        case .images: return "photo"
        case .video: return "film"
        case .audio: return "waveform"
        case .documents: return "doc.text"
        case .archives: return "archivebox"
        case .installers: return "shippingbox"
        case .other: return "doc"
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = String(localized: "tidy.choose")

        guard panel.runModal() == .OK, let selectedFolder = panel.url else { return }
        folder = selectedFolder
        model.scan(selectedFolder)
    }
}
