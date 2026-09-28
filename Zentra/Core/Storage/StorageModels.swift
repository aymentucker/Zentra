import Foundation

enum StorageCategory: String, CaseIterable, Hashable, Sendable {
    case documents, images, video, audio, archives, applications, developer, other
}

struct StorageItem: Identifiable, Hashable, Sendable {
    let url: URL
    let size: Int64
    let modifiedAt: Date?
    let category: StorageCategory
    var id: URL { url }
}

struct StorageAnalysis: Sendable {
    let items: [StorageItem]
    let categoryBytes: [StorageCategory: Int64]
    let totalBytes: Int64
    let skippedItems: Int

    var largeFiles: [StorageItem] {
        items.filter { $0.size >= 100 * 1_024 * 1_024 }.sorted { $0.size > $1.size }
    }
}

struct StorageClassifier: Sendable {
    func category(for url: URL) -> StorageCategory {
        let ext = url.pathExtension.lowercased()
        let path = url.path.lowercased()
        if path.contains("/library/developer/") || path.contains("/.gradle/") || path.contains("/.pub-cache/") { return .developer }
        if ["jpg","jpeg","png","gif","heic","webp","tiff","bmp","raw"].contains(ext) { return .images }
        if ["mov","mp4","m4v","avi","mkv","webm"].contains(ext) { return .video }
        if ["mp3","m4a","wav","aac","flac","aiff"].contains(ext) { return .audio }
        if ["zip","rar","7z","tar","gz","dmg","pkg"].contains(ext) { return .archives }
        if ["app"].contains(ext) { return .applications }
        if ["pdf","doc","docx","txt","rtf","pages","xls","xlsx","csv","ppt","pptx","key"].contains(ext) { return .documents }
        return .other
    }
}


struct StorageNode: Identifiable, Hashable, Sendable {
    let url: URL
    let name: String
    let directBytes: Int64
    let totalBytes: Int64
    let fileCount: Int
    let isDirectory: Bool
    let category: StorageCategory
    let children: [StorageNode]
    var id: URL { url }
}

struct StorageTreeBuilder: Sendable {
    func children(of directory: URL, from items: [StorageItem]) -> [StorageNode] {
        let base = directory.standardizedFileURL.path
        var directFiles: [StorageItem] = []
        var folders: [String: [StorageItem]] = [:]

        for item in items {
            let path = item.url.standardizedFileURL.path
            guard path.hasPrefix(base + "/") else { continue }
            let relative = String(path.dropFirst(base.count + 1))
            let parts = relative.split(separator: "/", maxSplits: 1).map(String.init)
            if parts.count == 1 { directFiles.append(item) }
            else { folders[parts[0], default: []].append(item) }
        }

        var nodes = directFiles.map {
            StorageNode(url: $0.url, name: $0.url.lastPathComponent, directBytes: $0.size, totalBytes: $0.size, fileCount: 1, isDirectory: false, category: $0.category, children: [])
        }

        for (name, values) in folders {
            let url = directory.appendingPathComponent(name)
            let bytes = values.reduce(Int64(0)) { $0 + $1.size }
            let dominant = Dictionary(grouping: values, by: \.category).max { a, b in
                a.value.reduce(Int64(0)) { $0 + $1.size } < b.value.reduce(Int64(0)) { $0 + $1.size }
            }?.key ?? .other
            nodes.append(StorageNode(url: url, name: name, directBytes: 0, totalBytes: bytes, fileCount: values.count, isDirectory: true, category: dominant, children: []))
        }
        return nodes.sorted { $0.totalBytes > $1.totalBytes }
    }
}
