import SwiftUI
import AppKit

struct DuplicatesView: View {
    @StateObject private var model = DuplicateFinderModel()
    @State private var roots: [URL] = []
    @State private var confirm = false

    var body: some View {
        ZStack {
            Color.zentraBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    if model.state == .scanning {
                        scanningCard
                    }

                    if let analysis = model.analysis {
                        metrics(analysis)
                        ForEach(analysis.groups) { group in
                            groupCard(group)
                        }
                    } else if model.state != .scanning {
                        emptyState
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 48)
                .padding(.vertical, 36)
            }

            if !model.selected.isEmpty {
                selectionBar
            }
        }
        .alert("duplicates.confirm.title", isPresented: $confirm) {
            Button("cleanup.cancel", role: .cancel) {}
            Button("storage.action.trash", role: .destructive) {
                model.trashSelected()
            }
        } message: {
            Text("duplicates.confirm.detail")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 7) {
                Text("duplicates.title").zentraFont(30, weight: .bold)
                Text("duplicates.subtitle")
                    .zentraFont(13)
                    .foregroundStyle(Color.zentraTextSecondary)
            }
            Spacer()
            if model.state == .scanning {
                Button("scan.cancel") { model.cancel() }
                    .buttonStyle(.plain)
            } else {
                ZentraPrimaryButton("duplicates.choose") { chooseFolders() }
            }
        }
    }

    private var scanningCard: some View {
        ZentraCard {
            HStack(spacing: 12) {
                ProgressView()
                VStack(alignment: .leading, spacing: 4) {
                    Text("duplicates.scanning").zentraFont(12, weight: .semibold)
                    Text("\(model.files) · \(ByteCountFormatter.string(fromByteCount: model.bytes, countStyle: .file))")
                        .zentraFont(10)
                        .foregroundStyle(Color.zentraTextTertiary)
                    if let currentURL = model.currentURL {
                        Text(currentURL.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .zentraFont(8.5)
                            .foregroundStyle(Color.zentraTextTertiary)
                    }
                }
                Spacer()
            }
        }
    }

    private func metrics(_ analysis: DuplicateAnalysis) -> some View {
        HStack(spacing: 12) {
            metric("duplicates.groups", "\(analysis.groups.count)")
            metric("duplicates.files", "\(analysis.duplicateFiles)")
            metric("duplicates.reclaim", ByteCountFormatter.string(fromByteCount: analysis.reclaimableBytes, countStyle: .file))
        }
    }

    private func metric(_ title: LocalizedStringKey, _ value: String) -> some View {
        ZentraCard {
            VStack(alignment: .leading, spacing: 6) {
                Text(value).zentraFont(18, weight: .semibold)
                Text(title).zentraFont(9.5).foregroundStyle(Color.zentraTextTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func groupCard(_ group: DuplicateGroup) -> some View {
        ZentraCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "square.stack.3d.up.fill").foregroundStyle(Color.zentraAccent)
                    Text(ByteCountFormatter.string(fromByteCount: group.size, countStyle: .file))
                        .zentraFont(12, weight: .semibold)
                    Text("· \(group.files.count)").foregroundStyle(Color.zentraTextTertiary)
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: group.reclaimableBytes, countStyle: .file))
                        .zentraFont(10)
                        .foregroundStyle(Color.zentraAccent)
                }

                ForEach(group.files) { file in
                    HStack(spacing: 10) {
                        Button { model.toggle(file.url) } label: {
                            Image(systemName: model.selected.contains(file.url) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(Color.zentraAccent)
                        }
                        .buttonStyle(.plain)

                        Image(systemName: "doc").foregroundStyle(Color.zentraTextTertiary)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(file.url.lastPathComponent).lineLimit(1).zentraFont(10.5)
                            Text(file.url.deletingLastPathComponent().path)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .zentraFont(8.5)
                                .foregroundStyle(Color.zentraTextTertiary)
                        }

                        Spacer()

                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([file.url])
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ZentraCard {
            VStack(spacing: 10) {
                Image(systemName: "square.on.square")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.zentraAccent)
                Text("duplicates.empty").zentraFont(14, weight: .semibold)
                Text("duplicates.empty.detail")
                    .zentraFont(10)
                    .foregroundStyle(Color.zentraTextTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
    }

    private var selectionBar: some View {
        VStack {
            Spacer()
            HStack {
                Text(String(format: NSLocalizedString("duplicates.selected", comment: ""), model.selected.count))
                    .zentraFont(11, weight: .semibold)
                Spacer()
                Button("storage.selection.clear") { model.selected = [] }
                    .buttonStyle(.plain)
                Button("storage.action.trash", role: .destructive) { confirm = true }
            }
            .padding(18)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .padding(20)
        }
    }

    private func chooseFolders() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = String(localized: "duplicates.choose")

        guard panel.runModal() == .OK else { return }
        roots = panel.urls
        model.start(roots: panel.urls)
    }
}
