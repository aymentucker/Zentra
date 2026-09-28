import Foundation

actor TidyAnalyzer {
    func analyze(folder:URL) async throws -> TidyAnalysis {
        let fm=FileManager.default;let keys:Set<URLResourceKey>=[.isRegularFileKey,.fileSizeKey]
        guard let e=fm.enumerator(at:folder,includingPropertiesForKeys:Array(keys),options:[.skipsSubdirectoryDescendants,.skipsPackageDescendants]) else{return .init(items:[])}
        var items:[TidyItem]=[]
        for case let url as URL in e {
            try Task.checkCancellation();guard let v=try? url.resourceValues(forKeys:keys),v.isRegularFile==true else{continue}
            items.append(.init(url:url,size:Int64(v.fileSize ?? 0),category:category(url)))
        }
        return .init(items:items.sorted{$0.size>$1.size})
    }
    private func category(_ url:URL)->TidyCategory {
        let e=url.pathExtension.lowercased()
        if ["jpg","jpeg","png","gif","heic","webp","svg"].contains(e){return .images}
        if ["mov","mp4","mkv","avi","m4v"].contains(e){return .video}
        if ["mp3","wav","m4a","aac","flac"].contains(e){return .audio}
        if ["pdf","doc","docx","txt","rtf","pages","xls","xlsx","csv","ppt","pptx"].contains(e){return .documents}
        if ["zip","rar","7z","tar","gz"].contains(e){return .archives}
        if ["dmg","pkg"].contains(e){return .installers}
        return .other
    }
}
