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
        var seen = Set<URL>()
        var lastProgress = ContinuousClock.now

        for root in StorageTargetPolicy().normalized(roots) where fm.fileExists(atPath: root.path) {
            try Task.checkCancellation()
            guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: Array(keys), options: [], errorHandler: { _, _ in
                skipped += 1
                return true
            }) else { skipped += 1; continue }

            for case let url as URL in enumerator {
                try Task.checkCancellation()
                let canonical = url.standardizedFileURL
                guard !StorageTargetPolicy().shouldSkip(canonical) else {
                    if let directoryEnumerator = enumerator as? FileManager.DirectoryEnumerator { directoryEnumerator.skipDescendants() }
                    continue
                }
                guard !seen.contains(canonical) else { continue }
                guard let values = try? canonical.resourceValues(forKeys: keys) else { skipped += 1; continue }
                guard values.isSymbolicLink != true, values.isDirectory != true, values.isRegularFile == true else { continue }
                seen.insert(canonical)
                let size = Int64(values.fileSize ?? 0)
                let category = classifier.category(for: canonical)
                items.append(StorageItem(url: canonical, size: size, modifiedAt: values.contentModificationDate, category: category))
                categoryBytes[category, default: 0] += size
                total += size

                let now = ContinuousClock.now
                if lastProgress.duration(to: now) >= .milliseconds(140) {
                    await progress?(items.count, total, canonical)
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
        let fm = FileManager.default
        let volume = URL(fileURLWithPath: "/", isDirectory: true)
        let data = URL(fileURLWithPath: "/System/Volumes/Data", isDirectory: true)
        return [volume, data].filter { fm.fileExists(atPath: $0.path) }
    }

    func normalized(_ roots: [URL]) -> [URL] {
        let sorted = roots.map(\.standardizedFileURL).sorted { $0.path.count < $1.path.count }
        var result: [URL] = []
        for root in sorted where !result.contains(where: { root.path == $0.path || root.path.hasPrefix($0.path + "/") }) {
            result.append(root)
        }
        return result
    }

    func shouldSkip(_ url: URL) -> Bool {
        let path = url.path
        let excluded = [
            "/dev", "/Volumes", "/System/Volumes/VM", "/System/Volumes/Preboot",
            "/System/Volumes/Update", "/System/Volumes/xarts", "/System/Volumes/iSCPreboot",
            "/System/Volumes/Hardware", "/private/var/vm"
        ]
        return excluded.contains { path == $0 || path.hasPrefix($0 + "/") }
    }
}
