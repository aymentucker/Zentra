import Foundation
import SwiftUI
import AppKit

struct StorageScanPreset: Identifiable, Hashable {
    let id: String
    let titleKey: String
    let icon: String
    let url: URL
}

struct StorageScanLocationCatalog {
    func presets() -> [StorageScanPreset] {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let candidates: [StorageScanPreset] = [
            .init(id:"disk", titleKey:"storage.location.disk", icon:"internaldrive", url: StorageTargetPolicy().defaultRoots().first ?? URL(fileURLWithPath:"/")),
            .init(id:"home", titleKey:"storage.location.home", icon:"house", url:home),
            .init(id:"desktop", titleKey:"storage.location.desktop", icon:"menubar.dock.rectangle", url:home.appendingPathComponent("Desktop")),
            .init(id:"documents", titleKey:"storage.location.documents", icon:"doc.text", url:home.appendingPathComponent("Documents")),
            .init(id:"downloads", titleKey:"storage.location.downloads", icon:"arrow.down.circle", url:home.appendingPathComponent("Downloads")),
            .init(id:"movies", titleKey:"storage.location.movies", icon:"film", url:home.appendingPathComponent("Movies")),
            .init(id:"pictures", titleKey:"storage.location.pictures", icon:"photo", url:home.appendingPathComponent("Pictures")),
            .init(id:"library", titleKey:"storage.location.library", icon:"books.vertical", url:home.appendingPathComponent("Library"))
        ]
        return candidates.filter { fm.fileExists(atPath:$0.url.path) }
    }
}

struct StorageLocationPicker: View {
    let presets: [StorageScanPreset]
    @Binding var selected: Set<String>
    @Binding var customURLs: [URL]
    let onAnalyze: ([URL]) -> Void
    @Environment(\.dismiss) private var dismiss

    private var selectedURLs: [URL] {
        StorageTargetPolicy().normalized(presets.filter { selected.contains($0.id) }.map(\.url) + customURLs)
    }

    var body: some View {
        VStack(alignment:.leading,spacing:18) {
            HStack {
                VStack(alignment:.leading,spacing:4) {
                    Text("storage.location.title").zentraFont(20,weight:.bold)
                    Text("storage.location.subtitle").zentraFont(10.5).foregroundStyle(Color.zentraTextTertiary)
                }
                Spacer()
                Button { dismiss() } label:{ Image(systemName:"xmark.circle.fill").font(.system(size:18)) }.buttonStyle(.plain).foregroundStyle(Color.zentraTextTertiary)
            }
            LazyVGrid(columns:[GridItem(.adaptive(minimum:180),spacing:10)],spacing:10) {
                ForEach(presets) { item in
                    Button { toggle(item) } label: {
                        HStack(spacing:10) {
                            Image(systemName:item.icon).foregroundStyle(Color.zentraAccent).frame(width:22)
                            VStack(alignment:.leading,spacing:2) {
                                Text(LocalizedStringKey(item.titleKey)).zentraFont(11.5,weight:.semibold)
                                Text(item.url.path).lineLimit(1).truncationMode(.middle).zentraFont(8).foregroundStyle(Color.zentraTextTertiary)
                            }
                            Spacer()
                            Image(systemName:selected.contains(item.id) ? "checkmark.circle.fill":"circle").foregroundStyle(selected.contains(item.id) ? Color.zentraAccent:Color.zentraTextTertiary)
                        }.padding(12).background(RoundedRectangle(cornerRadius:12).fill(selected.contains(item.id) ? Color.zentraAccent.opacity(0.09):Color.zentraSurface))
                    }.buttonStyle(.plain)
                }
            }
            if !customURLs.isEmpty {
                VStack(alignment:.leading,spacing:7) {
                    ForEach(customURLs,id:\.self) { url in
                        HStack { Image(systemName:"folder"); Text(url.path).lineLimit(1).truncationMode(.middle).zentraFont(9.5); Spacer(); Button { customURLs.removeAll{$0 == url} } label:{Image(systemName:"xmark")}.buttonStyle(.plain) }
                    }
                }
            }
            HStack {
                Button { chooseFolder() } label:{ Label("storage.location.custom",systemImage:"folder.badge.plus") }.buttonStyle(.plain).foregroundStyle(Color.zentraAccent)
                Spacer()
                Button("storage.location.all") { selectAll() }.buttonStyle(.plain).foregroundStyle(Color.zentraTextSecondary)
                ZentraPrimaryButton("storage.location.analyze") { let urls=selectedURLs; guard !urls.isEmpty else{return}; dismiss(); onAnalyze(urls) }
            }
        }.padding(24).frame(width:720)
    }

    private func toggle(_ item: StorageScanPreset) {
        if item.id == "disk" {
            if selected.contains("disk") { selected.remove("disk") } else { selected = ["disk"]; customURLs.removeAll() }
        } else {
            selected.remove("disk")
            if selected.contains(item.id) { selected.remove(item.id) } else { selected.insert(item.id) }
        }
    }

    private func selectAll() { selected = Set(presets.filter{$0.id != "disk"}.map(\.id)) }

    private func chooseFolder() {
        let panel=NSOpenPanel()
        panel.canChooseDirectories=true
        panel.canChooseFiles=false
        panel.allowsMultipleSelection=true
        panel.prompt=String(localized:"storage.location.choose")
        guard panel.runModal() == .OK else{return}
        selected.remove("disk")
        for url in panel.urls where !customURLs.contains(url) { customURLs.append(url) }
    }
}
