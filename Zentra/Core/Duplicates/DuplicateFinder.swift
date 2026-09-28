import Foundation
import CryptoKit

actor DuplicateFinder {
    typealias Progress = @Sendable (Int, Int64, URL?) async -> Void

    func find(
        roots: [URL],
        minimumSize: Int64 = 1_048_576,
        progress: Progress? = nil
    ) async throws -> DuplicateAnalysis {
        let fileManager = FileManager.default
        let keys: Set<URLResourceKey> = [
            .isRegularFileKey,
            .isSymbolicLinkKey,
            .fileSizeKey,
            .contentModificationDateKey
        ]

        var filesBySize: [Int64: [DuplicateFile]] = [:]
        var scannedFiles = 0
        var scannedBytes: Int64 = 0

        for root in StorageTargetPolicy().normalized(roots)
        where fileManager.fileExists(atPath: root.path) {
            try Task.checkCancellation()

            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: Array(keys),
                options: [.skipsPackageDescendants],
                errorHandler: { _, _ in true }
            ) else {
                continue
            }

            for case let url as URL in enumerator {
                try Task.checkCancellation()

                guard
                    let values = try? url.resourceValues(forKeys: keys),
                    values.isRegularFile == true,
                    values.isSymbolicLink != true
                else {
                    continue
                }

                let size = Int64(values.fileSize ?? 0)
                scannedFiles += 1
                scannedBytes += size

                if size >= minimumSize {
                    let file = DuplicateFile(
                        url: url.standardizedFileURL,
                        size: size,
                        modifiedAt: values.contentModificationDate
                    )
                    filesBySize[size, default: []].append(file)
                }

                if scannedFiles % 300 == 0 {
                    await progress?(scannedFiles, scannedBytes, url)
                    await Task.yield()
                }
            }
        }

        var groups: [DuplicateGroup] = []

        for (_, candidates) in filesBySize where candidates.count > 1 {
            var filesByHash: [String: [DuplicateFile]] = [:]

            for file in candidates {
                try Task.checkCancellation()
                let fingerprint = try hash(file.url)
                filesByHash[fingerprint, default: []].append(file)
            }

            for (fingerprint, matchingFiles) in filesByHash where matchingFiles.count > 1 {
                groups.append(
                    DuplicateGroup(
                        fingerprint: fingerprint,
                        files: matchingFiles.sorted { $0.url.path < $1.url.path }
                    )
                )
            }
        }

        await progress?(scannedFiles, scannedBytes, nil)

        return DuplicateAnalysis(
            groups: groups.sorted { $0.reclaimableBytes > $1.reclaimableBytes },
            scannedFiles: scannedFiles,
            scannedBytes: scannedBytes
        )
    }

    private func hash(_ url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        var digest = SHA256()

        while true {
            try Task.checkCancellation()
            guard let data = try handle.read(upToCount: 1_048_576), !data.isEmpty else {
                break
            }
            digest.update(data: data)
        }

        return digest.finalize()
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
