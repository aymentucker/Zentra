import Foundation
import AppKit

struct ApplicationRemovalResult: Sendable {
    let moved: [URL]
    let failed: [URL]
}

actor ApplicationRemovalExecutor {
    func execute(preview: ApplicationRemovalPreview, includeArtifacts: Set<URL>) async -> ApplicationRemovalResult {
        guard preview.application.safety != .protected else {
            return ApplicationRemovalResult(moved: [], failed: [preview.application.url])
        }
        var moved: [URL] = []
        var failed: [URL] = []
        let allowedArtifacts = Set(preview.artifacts.map { $0.url.standardizedFileURL })
        let requested = includeArtifacts.map { $0.standardizedFileURL }.filter { allowedArtifacts.contains($0) }
        let urls = requested + [preview.application.url.standardizedFileURL]

        for url in urls {
            do {
                if url == preview.application.url.standardizedFileURL {
                    var tag = 0
                    let success = NSWorkspace.shared.performFileOperation(
                        .recycleOperation,
                        source: url.deletingLastPathComponent().path,
                        destination: "",
                        files: [url.lastPathComponent],
                        tag: &tag
                    )
                    guard success else { throw CocoaError(.fileWriteNoPermission) }
                } else {
                    _ = try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                }
                guard !FileManager.default.fileExists(atPath: url.path) else { throw CocoaError(.fileWriteUnknown) }
                moved.append(url)
            } catch {
                failed.append(url)
            }
        }
        return ApplicationRemovalResult(moved: moved, failed: failed)
    }
}
