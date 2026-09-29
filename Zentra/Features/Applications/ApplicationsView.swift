import SwiftUI
import AppKit

struct ApplicationsView: View {
    @StateObject private var model = ApplicationManagerModel()
    let isActive: Bool

    init(isActive: Bool = true) { self.isActive = isActive }
    @State private var pendingUninstall: ApplicationRemovalPreview?
    @State private var pendingArtifacts = Set<URL>()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.zentraBackground, Color.zentraBackground, Color.zentraAccent.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if model.state == .scanning { scanningCard }
                    if let inventory = model.inventory {
                        metrics(inventory)
                        search
                        appList
                    } else if model.state != .scanning { emptyState }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 48).padding(.vertical, 36)
            }
        }
        .sheet(item: Binding(get: { model.preview.map(PreviewBox.init) }, set: { if $0 == nil { model.closePreview() } })) { box in
            removalPreview(box.value)
        }
        .alert("applications.confirm.title", isPresented: Binding(
            get: { pendingUninstall != nil },
            set: { if !$0 { pendingUninstall = nil } }
        )) {
            Button("cleanup.cancel", role: .cancel) { pendingUninstall = nil }
            Button("applications.uninstall", role: .destructive) {
                guard let request = pendingUninstall else { return }
                pendingUninstall = nil
                model.uninstall(request, selectedArtifacts: pendingArtifacts)
                pendingArtifacts = []
            }
        } message: { Text("applications.confirm.detail") }
        .alert("applications.permission.title", isPresented: Binding(
            get: { model.manualRemovalURL != nil },
            set: { if !$0 { model.manualRemovalURL = nil } }
        )) {
            Button("cleanup.cancel", role: .cancel) { model.manualRemovalURL = nil }
            Button("applications.permission.reveal") { model.revealManualRemoval() }
        } message: {
            Text("applications.permission.detail")
        }
        .alert("scan.error.title", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("common.retry") { model.errorMessage = nil; model.scan() }
        } message: { Text(model.errorMessage ?? "scan.error.message") }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 7) {
                Text("applications.title").zentraFont(30, weight: .bold).foregroundStyle(Color.zentraTextPrimary)
                Text("applications.subtitle").zentraFont(13).foregroundStyle(Color.zentraTextSecondary)
            }
            Spacer()
            ZentraPrimaryButton("applications.rescan") { model.scan() }
        }
    }

    private var scanningCard: some View {
        ZentraCard {
            HStack(spacing: 14) {
                ProgressView().controlSize(.small)
                VStack(alignment: .leading, spacing: 4) {
                    Text("applications.scanning").zentraFont(13, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                    Text("applications.scanning.detail").zentraFont(10.5).foregroundStyle(Color.zentraTextSecondary)
                }
                Spacer()
            }
        }
    }

    private func metrics(_ inventory: ApplicationInventory) -> some View {
        HStack(spacing: 12) {
            metric("applications.installed", "\(inventory.applications.count)", "square.grid.2x2")
            metric("applications.space", ByteCountFormatter.string(fromByteCount: inventory.totalBytes, countStyle: .file), "internaldrive")
            metric("applications.reviewable", "\(inventory.applications.filter { $0.safety != .protected }.count)", "checkmark.shield")
        }
    }

    private func metric(_ key: LocalizedStringKey, _ value: String, _ icon: String) -> some View {
        ZentraCard { VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon).foregroundStyle(Color.zentraAccent)
            Text(value).zentraFont(18, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
            Text(key).zentraFont(10).foregroundStyle(Color.zentraTextTertiary)
        }.frame(maxWidth: .infinity, alignment: .leading) }
    }

    private var search: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(Color.zentraTextTertiary)
            TextField("applications.search", text: $model.searchText).textFieldStyle(.plain).zentraFont(11)
        }.padding(.horizontal, 12).frame(height: 34).background(RoundedRectangle(cornerRadius: 10).fill(Color.zentraSurface))
    }

    private var appList: some View {
        LazyVStack(spacing: 8) {
            ForEach(model.filteredApplications) { app in
                Button { model.inspect(app) } label: {
                    HStack(spacing: 12) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path)).resizable().frame(width: 38, height: 38)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(app.name).zentraFont(12, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                            Text([app.version, app.bundleIdentifier].compactMap { $0 }.joined(separator: " · ")).lineLimit(1).zentraFont(9.5).foregroundStyle(Color.zentraTextTertiary)
                        }
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: app.appBytes, countStyle: .file)).zentraFont(10.5).foregroundStyle(Color.zentraTextSecondary)
                        safetyBadge(app.safety)
                        Image(systemName: "chevron.right").font(.system(size: 9)).foregroundStyle(Color.zentraTextTertiary)
                    }.padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Color.zentraSurface))
                }.buttonStyle(.plain)
                .contextMenu {
                    Button("storage.action.open") { model.open(app.url) }
                    Button("storage.action.reveal") { model.reveal(app.url) }
                }
            }
        }
    }

    private func safetyBadge(_ safety: ApplicationSafety) -> some View {
        let key: LocalizedStringKey = safety == .protected ? "applications.protected" : "applications.review"
        return Text(key).zentraFont(9, weight: .semibold)
            .foregroundStyle(safety == .protected ? Color.zentraTextTertiary : Color.zentraAccent)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(Capsule().fill(safety == .protected ? Color.white.opacity(0.04) : Color.zentraAccent.opacity(0.1)))
    }

    private var emptyState: some View {
        ZentraCard { VStack(spacing: 10) {
            Image(systemName: "square.grid.2x2").font(.system(size: 28)).foregroundStyle(Color.zentraAccent)
            Text("applications.empty").zentraFont(14, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
            Text("applications.empty.detail").zentraFont(11).foregroundStyle(Color.zentraTextSecondary)
        }.frame(maxWidth: .infinity).padding(.vertical, 26) }
    }

    private func removalPreview(_ preview: ApplicationRemovalPreview) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 13) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: preview.application.url.path)).resizable().frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text(preview.application.name).zentraFont(18, weight: .bold)
                    Text(preview.application.bundleIdentifier ?? preview.application.url.path).zentraFont(10).foregroundStyle(Color.zentraTextSecondary)
                }
                Spacer()
                Button { model.closePreview() } label: { Image(systemName: "xmark.circle.fill") }.buttonStyle(.plain)
            }
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("applications.preview.total").zentraFont(10).foregroundStyle(Color.zentraTextTertiary)
                    Text(ByteCountFormatter.string(fromByteCount: preview.totalBytes, countStyle: .file)).zentraFont(17, weight: .semibold)
                }
                Spacer()
                Text("applications.preview.note").zentraFont(9.5).foregroundStyle(Color.zentraTextTertiary)
            }
            artifactRow(title: "applications.appBundle", url: preview.application.url, bytes: preview.application.appBytes, selected: true, locked: true)
            ScrollView {
                VStack(spacing: 7) {
                    ForEach(preview.artifacts) { artifact in
                        artifactRow(title: artifact.kind.titleKey, url: artifact.url, bytes: artifact.bytes, selected: model.selectedArtifacts.contains(artifact.url), locked: false) {
                            model.toggleArtifact(artifact.url)
                        }
                    }
                }
            }
            if preview.artifacts.isEmpty {
                Text("applications.noLeftovers").zentraFont(10.5).foregroundStyle(Color.zentraTextSecondary)
            }
            HStack {
                Button("storage.action.reveal") { model.reveal(preview.application.url) }.buttonStyle(.plain)
                Spacer()
                if preview.application.safety == .protected {
                    Label("applications.protected.detail", systemImage: "lock.fill").zentraFont(10).foregroundStyle(Color.zentraTextTertiary)
                } else {
                    Button("applications.uninstall", role: .destructive) {
                        pendingArtifacts = model.selectedArtifacts
                        pendingUninstall = preview
                        model.closePreview()
                    }.disabled(model.isRemoving)
                }
            }
        }.padding(24).frame(width: 620, height: 600).background(Color.zentraBackground)
    }

    private func artifactRow(title: LocalizedStringKey, url: URL, bytes: Int64, selected: Bool, locked: Bool, action: (() -> Void)? = nil) -> some View {
        HStack(spacing: 10) {
            Button { action?() } label: { Image(systemName: locked ? "checkmark.circle.fill" : (selected ? "checkmark.circle.fill" : "circle")) }.buttonStyle(.plain).disabled(locked)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).zentraFont(10.5, weight: .medium)
                Text(url.path).lineLimit(1).zentraFont(8.5).foregroundStyle(Color.zentraTextTertiary)
            }
            Spacer()
            Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)).zentraFont(9.5).foregroundStyle(Color.zentraTextSecondary)
        }.padding(10).background(RoundedRectangle(cornerRadius: 10).fill(Color.zentraSurface))
    }
}

private struct PreviewBox: Identifiable {
    let value: ApplicationRemovalPreview
    var id: String { value.application.id }
}

private extension ApplicationArtifactKind {
    var titleKey: LocalizedStringKey {
        switch self {
        case .applicationSupport: "applications.artifact.support"
        case .caches: "applications.artifact.caches"
        case .preferences: "applications.artifact.preferences"
        case .savedState: "applications.artifact.savedState"
        case .logs: "applications.artifact.logs"
        case .containers: "applications.artifact.containers"
        case .groupContainers: "applications.artifact.groupContainers"
        }
    }
}
