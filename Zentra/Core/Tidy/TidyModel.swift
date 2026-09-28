import Foundation
import SwiftUI
import AppKit

@MainActor
final class TidyModel:ObservableObject {
    @Published private(set) var analysis:TidyAnalysis?
    @Published private(set) var isScanning=false
    @Published private(set) var isOrganizing=false
    @Published var selected=Set<URL>()
    @Published var errorMessage:String?
    private let analyzer=TidyAnalyzer()

    func scan(_ folder:URL){isScanning=true;Task{do{analysis=try await analyzer.analyze(folder:folder);selected=Set(analysis?.items.map(\.url) ?? []);isScanning=false}catch{errorMessage=error.localizedDescription;isScanning=false}}}
    func toggle(_ item:TidyItem){if selected.contains(item.url){selected.remove(item.url)}else{selected.insert(item.url)}}
    func organize(in folder:URL){
        guard let analysis else{return};isOrganizing=true
        for item in analysis.items where selected.contains(item.url) {
            let name:String
            switch item.category {case .images:name="Images";case .video:name="Videos";case .audio:name="Audio";case .documents:name="Documents";case .archives:name="Archives";case .installers:name="Installers";case .other:name="Other"}
            let destinationFolder=folder.appendingPathComponent("Zentra Organized").appendingPathComponent(name)
            do {try FileManager.default.createDirectory(at:destinationFolder,withIntermediateDirectories:true);var destination=destinationFolder.appendingPathComponent(item.url.lastPathComponent);var n=2
                while FileManager.default.fileExists(atPath:destination.path){destination=destinationFolder.appendingPathComponent("\(item.url.deletingPathExtension().lastPathComponent) \(n).\(item.url.pathExtension)");n += 1}
                try FileManager.default.moveItem(at:item.url,to:destination);selected.remove(item.url)
            } catch {errorMessage=error.localizedDescription}
        }
        isOrganizing=false;scan(folder)
    }
}
