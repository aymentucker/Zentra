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
