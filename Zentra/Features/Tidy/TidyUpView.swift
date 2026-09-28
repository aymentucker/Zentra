import SwiftUI
import AppKit

struct TidyUpView:View {
 @StateObject private var model=TidyModel();@State private var folder:URL?;@State private var confirm=false
 var body:some View{ZStack{Color.zentraBackground.ignoresSafeArea();ScrollView{VStack(alignment:.leading,spacing:22){
  HStack{VStack(alignment:.leading,spacing:7){Text("tidy.title").zentraFont(30,weight:.bold);Text("tidy.subtitle").zentraFont(13).foregroundStyle(Color.zentraTextSecondary)};Spacer();ZentraPrimaryButton("tidy.choose"){choose()}}
  if model.isScanning{ZentraCard{HStack{ProgressView();Text("tidy.scanning").zentraFont(12,weight:.semibold);Spacer()}}}
  if let a=model.analysis,let folder{HStack{Image(systemName:"folder.fill").foregroundStyle(Color.zentraAccent);Text(folder.path).lineLimit(1).truncationMode(.middle).zentraFont(10);Spacer();Text(ByteCountFormatter.string(fromByteCount:a.bytes,countStyle:.file)).zentraFont(11,weight:.semibold)}
   ForEach(TidyCategory.allCases){category in let values=a.items.filter{$0.category==category};if !values.isEmpty{section(category,values)}}
   HStack{Text(String(format:NSLocalizedString("tidy.selected",comment:""),model.selected.count)).zentraFont(11,weight:.semibold);Spacer();Button("storage.selection.clear"){model.selected=[]}.buttonStyle(.plain);ZentraPrimaryButton("tidy.organize"){confirm=true}}
  }else if !model.isScanning{ZentraCard{VStack(spacing:10){Image(systemName:"square.grid.2x2").font(.system(size:28)).foregroundStyle(Color.zentraAccent);Text("tidy.empty").zentraFont(14,weight:.semibold);Text("tidy.empty.detail").zentraFont(10).foregroundStyle(Color.zentraTextTertiary)}.frame(maxWidth:.infinity).padding(24)}}
 }}.frame(maxWidth:.infinity).padding(.horizontal,48).padding(.vertical,36)}}
 .alert("tidy.confirm.title",isPresented:$confirm){Button("cleanup.cancel",role:.cancel){};Button("tidy.organize"){if let folder{model.organize(in:folder)}}}message:{Text("tidy.confirm.detail")}
 }
 private func section(_ category:TidyCategory,_ items:[TidyItem])->some View{ZentraCard{VStack(alignment:.leading,spacing:9){HStack{Image(systemName:icon(category)).foregroundStyle(Color.zentraAccent);Text(LocalizedStringKey("tidy.category.\(category.rawValue)")).zentraFont(12,weight:.semibold);Spacer();Text("\(items.count)").zentraFont(9).foregroundStyle(Color.zentraTextTertiary)}
  ForEach(items.prefix(100)){item in HStack{Button{model.toggle(item)}label:{Image(systemName:model.selected.contains(item.url) ? "checkmark.circle.fill":"circle").foregroundStyle(Color.zentraAccent)}.buttonStyle(.plain);Text(item.url.lastPathComponent).lineLimit(1).zentraFont(10);Spacer();Text(ByteCountFormatter.string(fromByteCount:item.size,countStyle:.file)).zentraFont(9).foregroundStyle(Color.zentraTextTertiary)}}}}}
 private func icon(_ c:TidyCategory)->String{switch c{case .images:"photo";case .video:"film";case .audio:"waveform";case .documents:"doc.text";case .archives:"archivebox";case .installers:"shippingbox";case .other:"doc"}}
 private func choose(){let p=NSOpenPanel();p.canChooseDirectories=true;p.canChooseFiles=false;p.allowsMultipleSelection=false;p.prompt=String(localized:"tidy.choose");guard p.runModal() == .OK,let u=p.url else{return};folder=u;model.scan(u)}
}
