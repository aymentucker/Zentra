import Foundation

actor StorageAnalyzer {
    typealias ProgressHandler = @Sendable (_ files: Int, _ bytes: Int64, _ current: URL?) async -> Void

    func analyze(roots: [URL], progress: ProgressHandler? = nil) async throws -> StorageAnalysis {
        let fm = FileManager.default
        let classifier = StorageClassifier()
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey]
        var items: [StorageItem] = []
        var categoryBytes: [StorageCategory: Int64] = [:]
        var total: Int64 = 0
        var skipped = 0
        var lastProgress = ContinuousClock.now

        for root in roots where fm.fileExists(atPath: root.path) {
            try Task.checkCancellation()
            guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles, .skipsPackageDescendants], errorHandler: { _, _ in true }) else {
                skipped += 1
                continue
            }
            for case let url as URL in enumerator {
                try Task.checkCancellation()
                guard let values = try? url.resourceValues(forKeys: keys) else { skipped += 1; continue }
                guard values.isSymbolicLink != true, values.isDirectory != true, values.isRegularFile == true else { continue }
                let size = Int64(values.fileSize ?? 0)
                let category = classifier.category(for: url)
                items.append(StorageItem(url: url, size: size, modifiedAt: values.contentModificationDate, category: category))
                categoryBytes[category, default: 0] += size
                total += size
                let now = ContinuousClock.now
                if lastProgress.duration(to: now) >= .milliseconds(140) {
                    await progress?(items.count, total, url)
                    lastProgress = now
                    await Task.yield()
                }
            }
        }
        await progress?(items.count, total, nil)
        return StorageAnalysis(items: items, categoryBytes: categoryBytes, totalBytes: total, skippedItems: skipped)
    }
}

struct StorageTargetPolicy: Sendable {
    func defaultRoots() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let names = ["Desktop", "Documents", "Downloads", "Movies", "Music", "Pictures"]
        return names.map { home.appendingPathComponent($0) }.filter { FileManager.default.fileExists(atPath: $0.path) }
    }
}
