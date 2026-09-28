import Foundation

struct CleanupSourceSummary: Identifiable, Sendable {
    let source: CleanupSource
    let itemCount: Int
    let totalBytes: Int64
    var id: CleanupSourceKind { source.kind }
}

actor CleanupSourceAnalyzer {
    private let scanner = FileSystemScanner()

    func analyze(_ sources: [CleanupSource]) async -> [CleanupSourceSummary] {
        var summaries: [CleanupSourceSummary] = []
        for source in sources {
            if Task.isCancelled { break }
            guard !source.targets.isEmpty else {
                summaries.append(CleanupSourceSummary(source: source, itemCount: 0, totalBytes: 0))
                continue
            }
            do {
                let result = try await scanner.scan(targets: source.targets)
                summaries.append(CleanupSourceSummary(source: source, itemCount: result.fileCount, totalBytes: result.totalBytes))
            } catch {
                summaries.append(CleanupSourceSummary(source: source, itemCount: 0, totalBytes: 0))
            }
        }
        return summaries
    }
}
