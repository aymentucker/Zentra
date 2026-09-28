import Foundation

actor FileSystemScanner {
    typealias ProgressHandler = @Sendable (ScanProgress) async -> Void

    func scan(targets: [ScanTarget], progress: ProgressHandler? = nil) async throws -> ScanSummary {
        var files: [ScannedFile] = []
        var totalBytes: Int64 = 0
        var skipped = 0
        var discoveredCount = 0
        var lastProgress = ContinuousClock.now

        let keys: Set<URLResourceKey> = [.isRegularFileKey, .isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .isSymbolicLinkKey]

        for target in targets {
            try Task.checkCancellation()

            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: target.url.path, isDirectory: &isDirectory) else {
                throw ScannerError.invalidTarget(target.url)
            }

            if !isDirectory.boolValue {
                if let item = readItem(target.url, keys: keys) {
                    files.append(item)
                    discoveredCount += 1
                    totalBytes += item.size
                }
                continue
            }

            guard let enumerator = FileManager.default.enumerator(
                at: target.url,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { _, _ in true }
            ) else {
                skipped += 1
                continue
            }

            for case let url as URL in enumerator {
                try Task.checkCancellation()
                guard let values = try? url.resourceValues(forKeys: keys) else {
                    skipped += 1
                    continue
                }

                if values.isSymbolicLink == true { continue }

                let isDir = values.isDirectory == true
                guard !isDir else { continue }

                let size = Int64(values.fileSize ?? 0)
                files.append(ScannedFile(id: url, url: url, size: size, isDirectory: false, modifiedAt: values.contentModificationDate))
                discoveredCount += 1
                totalBytes += size

                let now = ContinuousClock.now
                if lastProgress.duration(to: now) >= .milliseconds(120) {
                    await progress?(ScanProgress(discoveredItems: discoveredCount, discoveredBytes: totalBytes, currentURL: url))
                    lastProgress = now
                    await Task.yield()
                }
            }
        }

        await progress?(ScanProgress(discoveredItems: discoveredCount, discoveredBytes: totalBytes, currentURL: nil))
        return ScanSummary(files: files, totalBytes: totalBytes, skippedItems: skipped)
    }

    private func readItem(_ url: URL, keys: Set<URLResourceKey>) -> ScannedFile? {
        guard let values = try? url.resourceValues(forKeys: keys), values.isSymbolicLink != true else { return nil }
        let isDirectory = values.isDirectory == true
        return ScannedFile(
            id: url,
            url: url,
            size: isDirectory ? 0 : Int64(values.fileSize ?? 0),
            isDirectory: isDirectory,
            modifiedAt: values.contentModificationDate
        )
    }
}
