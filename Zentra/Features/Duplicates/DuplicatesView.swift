import SwiftUI
import AppKit

struct DuplicatesView:View {
 @StateObject private var model=DuplicateFinderModel();@State private var roots:[URL]=[];@State private var confirm=false
 var body:some View{ZStack{Color.zentraBackground.ignoresSafeArea();ScrollView{VStack(alignment:.leading,spacing:22){
  HStack{VStack(alignment:.leading,spacing:7){Text("duplicates.title").zentraFont(30,weight:.bold);Text("duplicates.subtitle").zentraFont(13).foregroundStyle(Color.zentraTextSecondary)};Spacer()
   if model.state == .scanning{Button("scan.cancel"){model.cancel()}.buttonStyle(.plain)}else{ZentraPrimaryButton("duplicates.choose"){choose()}}}
  if model.state == .scanning{ZentraCard{HStack{ProgressView();VStack(alignment:.leading){Text("duplicates.scanning").zentraFont(12,weight:.semibold);Text("\(model.files) · \(ByteCountFormatter.string(fromByteCount:model.bytes,countStyle:.file))").zentraFont(10).foregroundStyle(Color.zentraTextTertiary)};Spacer()}}}
  if let a=model.analysis{HStack(spacing:12){metric("duplicates.groups","\(a.groups.count)");metric("duplicates.files","\(a.duplicateFiles)");metric("duplicates.reclaim",ByteCountFormatter.string(fromByteCount:a.reclaimableBytes,countStyle:.file))}
   ForEach(a.groups){g in group(g)}
  } else if model.state != .scanning{ZentraCard{VStack(spacing:10){Image(systemName:"square.on.square").font(.system(size:28)).foregroundStyle(Color.zentraAccent);Text("duplicates.empty").zentraFont(14,weight:.semibold);Text("duplicates.empty.detail").zentraFont(10).foregroundStyle(Color.zentraTextTertiary)}.frame(maxWidth:.infinity).padding(24)}}
 }}.frame(maxWidth:.infinity).padding(.horizontal,48).padding(.vertical,36)}
 if !model.selected.isEmpty{VStack{Spacer();HStack{Text(String(format:NSLocalizedString("duplicates.selected",comment:""),model.selected.count)).zentraFont(11,weight:.semibold);Spacer();Button("storage.selection.clear"){model.selected=[]}.buttonStyle(.plain);Button("storage.action.trash",role:.destructive){confirm=true}}.padding(18).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius:15)).padding(20)}}}
 .alert("duplicates.confirm.title",isPresented:$confirm){Button("cleanup.cancel",role:.cancel){};Button("storage.action.trash",role:.destructive){model.trashSelected()}}message:{Text("duplicates.confirm.detail")}
 }
 private func metric(_ t:LocalizedStringKey,_ v:String)->some View{ZentraCard{VStack(alignment:.leading,spacing:6){Text(v).zentraFont(18,weight:.semibold);Text(t).zentraFont(9.5).foregroundStyle(Color.zentraTextTertiary)}.frame(maxWidth:.infinity,alignment:.leading)}}
 private func group(_ g:DuplicateGroup)->some View{ZentraCard{VStack(alignment:.leading,spacing:10){HStack{Image(systemName:"square.stack.3d.up.fill").foregroundStyle(Color.zentraAccent);Text(ByteCountFormatter.string(fromByteCount:g.size,countStyle:.file)).zentraFont(12,weight:.semibold);Text("· \(g.files.count)").foregroundStyle(Color.zentraTextTertiary);Spacer();Text(ByteCountFormatter.string(fromByteCount:g.reclaimableBytes,countStyle:.file)).zentraFont(10).foregroundStyle(Color.zentraAccent)}
  ForEach(g.files){f in HStack{Button{model.toggle(f.url)}label:{Image(systemName:model.selected.contains(f.url) ? "checkmark.circle.fill":"circle").foregroundStyle(Color.zentraAccent)}.buttonStyle(.plain);Image(systemName:"doc").foregroundStyle(Color.zentraTextTertiary);VStack(alignment:.leading){Text(f.url.lastPathComponent).lineLimit(1).zentraFont(10.5);Text(f.url.deletingLastPathComponent().path).lineLimit(1).truncationMode(.middle).zentraFont(8.5).foregroundStyle(Color.zentraTextTertiary)};Spacer();Button{NSWorkspace.shared.activateFileViewerSelecting([f.url])}label:{Image(systemName:"magnifyingglass")}.buttonStyle(.plain)}}}}}
 private func choose(){let p=NSOpenPanel();p.canChooseDirectories=true;p.canChooseFiles=false;p.allowsMultipleSelection=true;p.prompt=String(localized:"duplicates.choose");guard p.runModal() == .OK else{return};roots=p.urls;model.start(roots:p.urls)}
}
