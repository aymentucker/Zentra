import SwiftUI
import AppKit

struct DeveloperCleanerView: View {
    @StateObject private var model = WorkspaceCleanerModel()
    @State private var tab: CleanerTab = .developer
    @State private var showingConfirmation = false

    enum CleanerTab: String, CaseIterable { case developer, creator }

    var body: some View {
        ZStack {
            LinearGradient(colors:[Color.zentraBackground,Color.zentraBackground,Color.zentraAccent.opacity(0.045)],startPoint:.topLeading,endPoint:.bottomTrailing).ignoresSafeArea()
            ScrollView {
                VStack(alignment:.leading,spacing:22) {
                    header
                    HStack(spacing: 8) {
                        cleanerTabButton(
                            .developer,
                            title: "developer.tab.developer",
                            icon: "chevron.left.forwardslash.chevron.right"
                        )
                        cleanerTabButton(
                            .creator,
                            title: "developer.tab.creator",
                            icon: "wand.and.stars"
                        )
                        Spacer()
                    }

                    if model.isScanning { scanCard }
                    else if model.results.filter({ $0.location.group.isCreator == (tab == .creator) }).isEmpty { emptyCard }
                    else { results }

                    if !model.selectedResults.isEmpty { actionBar }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 48)
                .padding(.vertical, 36)
            }
        }
        .alert("developer.confirm.title",isPresented:$showingConfirmation) {
            Button("cleanup.cancel",role:.cancel){}
            Button("cleanup.confirm.action",role:.destructive){ model.moveSelectedToTrash() }
        } message: {
            Text(String(format:NSLocalizedString("developer.confirm.detail",comment:""),model.selectedResults.count,ByteCountFormatter.string(fromByteCount:model.selectedBytes,countStyle:.file)))
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment:.leading,spacing:7) {
                Text("developer.title").zentraFont(30,weight:.bold).foregroundStyle(Color.zentraTextPrimary)
                Text("developer.subtitle").zentraFont(13).foregroundStyle(Color.zentraTextSecondary)
            }
            Spacer()
            if model.isScanning { Button("scan.cancel"){model.cancel()}.buttonStyle(.plain) }
            else { Button { model.scan() } label:{ Label("developer.rescan",systemImage:"arrow.clockwise") }.buttonStyle(.plain).foregroundStyle(Color.zentraAccent) }
        }
    }

    private func cleanerTabButton(
        _ value: CleanerTab,
        title: LocalizedStringKey,
        icon: String
    ) -> some View {
        let selected = tab == value
        return Button {
            withAnimation(.easeInOut(duration: 0.16)) {
                tab = value
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .zentraFont(11, weight: .semibold)
            }
            .foregroundStyle(selected ? Color.zentraTextPrimary : Color.zentraTextSecondary)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selected ? Color.zentraAccent.opacity(0.16) : Color.zentraSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selected ? Color.zentraAccent.opacity(0.50) : Color.white.opacity(0.04), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var scanCard: some View {
        ZentraCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.zentraAccent.opacity(0.10))
                            .frame(width: 42, height: 42)
                        ProgressView()
                            .controlSize(.small)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("developer.scanning")
                            .zentraFont(13, weight: .semibold)
                            .foregroundStyle(Color.zentraTextPrimary)
                        Text("developer.scanning.detail")
                            .zentraFont(10)
                            .foregroundStyle(Color.zentraTextTertiary)
                    }
                    Spacer()
                }

                HStack(spacing: 8) {
                    ForEach(scanGroups, id: \.self) { group in
                        HStack(spacing: 6) {
                            Image(systemName: icon(group))
                                .font(.system(size: 10, weight: .medium))
                            Text(groupLabel(group))
                                .zentraFont(9, weight: .medium)
                        }
                        .foregroundStyle(Color.zentraTextSecondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.045))
                        )
                    }
                    Spacer()
                }

                ProgressView()
                    .progressViewStyle(.linear)
                    .tint(Color.zentraAccent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var scanGroups: [WorkspaceCleanerGroup] {
        tab == .developer
            ? [.xcode, .flutter, .node, .gradle, .cocoaPods, .homebrew, .docker]
            : [.adobe, .davinci, .finalCut]
    }

    private func groupLabel(_ group: WorkspaceCleanerGroup) -> String {
        switch group {
        case .xcode: return "Xcode"
        case .flutter: return "Flutter"
        case .node: return "Node"
        case .gradle: return "Gradle"
        case .cocoaPods: return "CocoaPods"
        case .homebrew: return "Homebrew"
        case .docker: return "Docker"
        case .adobe: return "Adobe"
        case .davinci: return "DaVinci"
        case .finalCut: return "Final Cut"
        }
    }

    private var emptyCard: some View {
        ZentraCard {
            VStack(spacing:10) {
                Image(systemName:"checkmark.shield.fill").font(.system(size:30)).foregroundStyle(Color.zentraAccent)
                Text("developer.empty").zentraFont(13,weight:.semibold)
                Text("developer.empty.detail").zentraFont(10).foregroundStyle(Color.zentraTextTertiary)
            }.frame(maxWidth:.infinity).padding(20)
        }
    }

    private var results: some View {
        let values = model.results.filter { $0.location.group.isCreator == (tab == .creator) }
        return VStack(spacing:10) {
            ForEach(values) { result in
                ZentraCard {
                    HStack(spacing:14) {
                        Image(systemName: icon(result.location.group)).font(.system(size:17,weight:.medium)).foregroundStyle(Color.zentraAccent)
                            .frame(width:38,height:38).background(Circle().fill(Color.zentraAccent.opacity(0.1)))
                        VStack(alignment:.leading,spacing:4) {
                            HStack(spacing:7) {
                                Text(result.location.name).zentraFont(12.5,weight:.semibold)
                                safetyBadge(result.location.safety)
                            }
                            Text(result.location.detail).zentraFont(9.5).foregroundStyle(Color.zentraTextTertiary)
                            Text(result.location.url.path).lineLimit(1).truncationMode(.middle).zentraFont(8.5).foregroundStyle(Color.zentraTextTertiary.opacity(0.75))
                        }
                        Spacer()
                        VStack(alignment:.trailing,spacing:5) {
                            Text(ByteCountFormatter.string(fromByteCount:result.bytes,countStyle:.file)).zentraFont(12,weight:.semibold)
                            Text(String(format:NSLocalizedString("developer.files",comment:""),result.fileCount)).zentraFont(8.5).foregroundStyle(Color.zentraTextTertiary)
                        }
                        Button { model.toggle(result) } label: {
                            Image(systemName:model.selected.contains(result.id) ? "checkmark.circle.fill" : (result.location.safety == .protected ? "lock.fill" : "circle"))
                                .foregroundStyle(result.location.safety == .protected ? Color.zentraTextTertiary : Color.zentraAccent).font(.system(size:16))
                        }.buttonStyle(.plain).disabled(result.location.safety == .protected)
                    }
                    .contextMenu {
                        Button("storage.action.reveal"){ NSWorkspace.shared.activateFileViewerSelecting([result.location.url]) }
                    }
                }
            }
        }
    }

    private var actionBar: some View {
        ZentraCard {
            HStack {
                VStack(alignment:.leading,spacing:3) {
                    Text(String(format:NSLocalizedString("developer.selected",comment:""),model.selectedResults.count)).zentraFont(12,weight:.semibold)
                    Text(ByteCountFormatter.string(fromByteCount:model.selectedBytes,countStyle:.file)).zentraFont(10).foregroundStyle(Color.zentraTextTertiary)
                }
                Spacer()
                if model.isCleaning { ProgressView().controlSize(.small) }
                ZentraPrimaryButton("developer.clean"){ showingConfirmation = true }
            }
        }
    }

    private func safetyBadge(_ safety: WorkspaceSafety) -> some View {
        Text(LocalizedStringKey("developer.safety.\(safety.rawValue)")).zentraFont(8,weight:.semibold)
            .padding(.horizontal,7).padding(.vertical,3)
            .background(Capsule().fill(safety == .safe ? Color.zentraAccent.opacity(0.13) : Color.white.opacity(0.06)))
            .foregroundStyle(safety == .protected ? Color.zentraTextTertiary : Color.zentraAccent)
    }

    private func icon(_ group: WorkspaceCleanerGroup) -> String {
        switch group {
        case .xcode: "hammer.fill"; case .flutter: "swift"; case .node: "shippingbox.fill"; case .gradle: "cube.fill"
        case .cocoaPods: "circle.hexagongrid.fill"; case .homebrew: "mug.fill"; case .docker: "shippingbox"
        case .adobe: "a.square.fill"; case .davinci: "film.stack.fill"; case .finalCut: "film.fill"
        }
    }
}
