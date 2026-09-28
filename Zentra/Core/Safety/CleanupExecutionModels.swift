import Foundation

struct CleanupExecutionItem: Sendable {
    let sourceURL: URL
    let destinationURL: URL?
    let size: Int64
    let succeeded: Bool
    let message: String?
}

struct CleanupExecutionReport: Sendable {
    let startedAt: Date
    let finishedAt: Date
    let items: [CleanupExecutionItem]

    var succeededCount: Int { items.filter(\.succeeded).count }
    var failedCount: Int { items.count - succeededCount }
    var processedBytes: Int64 {
        items.filter(\.succeeded).reduce(0) { $0 + $1.size }
    }
}

enum CleanupExecutionError: LocalizedError {
    case sourceMissing(URL)
    case destinationUnavailable
    case verificationFailed(URL)

    var errorDescription: String? {
        switch self {
        case .sourceMissing(let url): "The source item no longer exists: \(url.path)"
        case .destinationUnavailable: "A recoverable destination was not returned."
        case .verificationFailed(let url): "The operation could not be verified: \(url.path)"
        }
    }
}
