import Foundation

struct ScanTarget: Identifiable, Hashable, Sendable {
    let id: UUID
    let url: URL
    let displayName: String

    init(url: URL, displayName: String? = nil) {
        self.id = UUID()
        self.url = url
        self.displayName = displayName ?? url.lastPathComponent
    }
}

struct ScannedFile: Identifiable, Hashable, Sendable {
    let id: URL
    let url: URL
    let size: Int64
    let isDirectory: Bool
    let modifiedAt: Date?
}

struct ScanSummary: Sendable {
    let files: [ScannedFile]
    let totalBytes: Int64
    let skippedItems: Int

    var fileCount: Int { files.count }
}

struct ScanProgress: Sendable {
    let discoveredItems: Int
    let discoveredBytes: Int64
    let currentURL: URL?
}

enum ScannerError: LocalizedError {
    case invalidTarget(URL)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidTarget(let url): "Cannot scan \(url.path)."
        case .cancelled: "The scan was cancelled."
        }
    }
}
