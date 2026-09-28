import Foundation

enum WorkspaceCleanerGroup: String, CaseIterable, Identifiable, Sendable {
    case xcode, flutter, node, gradle, cocoaPods, homebrew, docker
    case adobe, davinci, finalCut

    var id: String { rawValue }
    var isCreator: Bool { [.adobe, .davinci, .finalCut].contains(self) }
}

enum WorkspaceSafety: String, Sendable { case safe, review, protected }

struct WorkspaceCleanupLocation: Identifiable, Hashable, Sendable {
    let id: String
    let group: WorkspaceCleanerGroup
    let name: String
    let url: URL
    let safety: WorkspaceSafety
    let detail: String
}

struct WorkspaceCleanupResult: Identifiable, Sendable {
    let location: WorkspaceCleanupLocation
    let bytes: Int64
    let fileCount: Int
    let exists: Bool
    var id: String { location.id }
}

struct WorkspaceCleanupCatalog: Sendable {
    func locations() -> [WorkspaceCleanupLocation] {
        let h = FileManager.default.homeDirectoryForCurrentUser
        func u(_ p: String) -> URL { h.appendingPathComponent(p) }
        return [
            .init(id:"xcode-derived",group:.xcode,name:"Derived Data",url:u("Library/Developer/Xcode/DerivedData"),safety:.safe,detail:"Rebuildable Xcode build products and indexes."),
            .init(id:"xcode-device",group:.xcode,name:"iOS Device Support",url:u("Library/Developer/Xcode/iOS DeviceSupport"),safety:.review,detail:"Device symbols/support. Xcode may download them again."),
            .init(id:"xcode-archives",group:.xcode,name:"Archives",url:u("Library/Developer/Xcode/Archives"),safety:.protected,detail:"Release archives are protected and never auto-selected."),
            .init(id:"flutter-pub",group:.flutter,name:"Dart Pub Cache",url:u(".pub-cache"),safety:.safe,detail:"Downloaded Dart/Flutter package cache."),
            .init(id:"flutter-cache",group:.flutter,name:"Flutter SDK Cache",url:u("Library/Caches/flutter_engine"),safety:.review,detail:"Rebuildable engine artifacts when present."),
            .init(id:"node-npm",group:.node,name:"npm Cache",url:u(".npm/_cacache"),safety:.safe,detail:"npm content-addressable download cache."),
            .init(id:"node-pnpm",group:.node,name:"pnpm Store",url:u("Library/pnpm/store"),safety:.review,detail:"Shared package store; review before removing."),
            .init(id:"node-yarn",group:.node,name:"Yarn Cache",url:u("Library/Caches/Yarn"),safety:.safe,detail:"Downloaded Yarn package cache."),
            .init(id:"gradle",group:.gradle,name:"Gradle Caches",url:u(".gradle/caches"),safety:.safe,detail:"Rebuildable Gradle dependency/build caches."),
            .init(id:"pods",group:.cocoaPods,name:"CocoaPods Cache",url:u("Library/Caches/CocoaPods"),safety:.safe,detail:"Downloaded CocoaPods cache; project Pods are untouched."),
            .init(id:"brew",group:.homebrew,name:"Homebrew Cache",url:u("Library/Caches/Homebrew"),safety:.safe,detail:"Downloaded bottles and source archives."),
            .init(id:"docker",group:.docker,name:"Docker Desktop Data",url:u("Library/Containers/com.docker.docker/Data"),safety:.protected,detail:"May contain images, volumes and databases; inspect in Docker."),
            .init(id:"adobe",group:.adobe,name:"Adobe Cache",url:u("Library/Caches/Adobe"),safety:.safe,detail:"Adobe application cache. Projects and source media are untouched."),
            .init(id:"davinci",group:.davinci,name:"DaVinci CacheClip",url:u("Library/Application Support/Blackmagic Design/DaVinci Resolve/CacheClip"),safety:.safe,detail:"Generated Resolve cache media."),
            .init(id:"fcp",group:.finalCut,name:"Final Cut Cache",url:u("Library/Caches/com.apple.FinalCut"),safety:.review,detail:"Application cache only; libraries and media remain protected.")
        ]
    }
}
