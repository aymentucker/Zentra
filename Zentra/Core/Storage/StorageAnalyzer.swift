import Foundation

actor StorageAnalyzer {
    typealias ProgressHandler = @Sendable (_ files: Int, _ bytes: Int64, _ current: URL?) async -> Void

    func analyze(roots: [URL], progress: ProgressHandler? = nil) async throws -> StorageAnalysis {
        let fm = FileManager.default
        let classifier = StorageClassifier()
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey, .contentModificationDateKey]
        var items: [StorageItem] = []
        var categoryBytes: [StorageCategory: Int64] = [:]
        var total: Int64 = 0
        var skipped = 0
        let skippedCounter = LockedCounter()
        var seen = Set<URL>()
        var lastProgress = ContinuousClock.now

        for root in StorageTargetPolicy().normalized(roots) where fm.fileExists(atPath: root.path) {
            try Task.checkCancellation()
            guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: Array(keys), options: [], errorHandler: { _, _ in
                skippedCounter.increment()
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
                let logicalSize = Int64(values.fileSize ?? 0)
                let allocatedSize = Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? values.fileSize ?? 0)
                let size = max(0, min(logicalSize, allocatedSize))
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
        skipped += skippedCounter.value
        await progress?(items.count, total, nil)
        return StorageAnalysis(items: items, categoryBytes: categoryBytes, totalBytes: total, skippedItems: skipped)
    }
}

struct StorageTargetPolicy: Sendable {
    func defaultRoots() -> [URL] {
        let fm = FileManager.default
        // Scan the writable APFS Data volume once. Scanning "/" on modern macOS also
        // traverses firmlinks into Data and can count the same physical content twice.
        let data = URL(fileURLWithPath: "/System/Volumes/Data", isDirectory: true)
        if fm.fileExists(atPath: data.path) { return [data] }
        return [URL(fileURLWithPath: "/", isDirectory: true)]
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


private final class LockedCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var storage = 0
    func increment() { lock.lock(); storage += 1; lock.unlock() }
    var value: Int { lock.lock(); defer { lock.unlock() }; return storage }
}
