import Foundation
import AppKit

enum ApplicationRemovalFailureKind: Sendable { case permission, other }

struct ApplicationRemovalFailure: Sendable {
    let url: URL
    let kind: ApplicationRemovalFailureKind
}

struct ApplicationRemovalResult: Sendable {
    let moved: [URL]
    let failures: [ApplicationRemovalFailure]
    var failed: [URL] { failures.map(\.url) }
    var applicationNeedsManualRemoval: Bool {
        failures.contains { $0.kind == .permission && $0.url.pathExtension.lowercased() == "app" }
    }
}

actor ApplicationRemovalExecutor {
    func execute(preview: ApplicationRemovalPreview, includeArtifacts: Set<URL>) async -> ApplicationRemovalResult {
        guard preview.application.safety != .protected else {
            return .init(moved: [], failures: [.init(url: preview.application.url, kind: .other)])
        }

        let appURL = preview.application.url.standardizedFileURL
        var tag = 0
        let recycled = NSWorkspace.shared.performFileOperation(
            .recycleOperation,
            source: appURL.deletingLastPathComponent().path,
            destination: "",
            files: [appURL.lastPathComponent],
            tag: &tag
        )

        // Never remove leftovers if the app bundle itself could not be removed.
        guard recycled, !FileManager.default.fileExists(atPath: appURL.path) else {
            return .init(moved: [], failures: [.init(url: appURL, kind: .permission)])
        }

        let artifactResult = await executeArtifactsOnly(preview: preview, includeArtifacts: includeArtifacts)
        return .init(moved: [appURL] + artifactResult.moved, failures: artifactResult.failures)
    }

    func executeArtifactsOnly(preview: ApplicationRemovalPreview, includeArtifacts: Set<URL>) async -> ApplicationRemovalResult {
        var moved: [URL] = []
        var failures: [ApplicationRemovalFailure] = []
        let allowed = Set(preview.artifacts.map { $0.url.standardizedFileURL })
        let requested = includeArtifacts.map { $0.standardizedFileURL }.filter { allowed.contains($0) }

        for url in requested where FileManager.default.fileExists(atPath: url.path) {
            do {
                _ = try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                guard !FileManager.default.fileExists(atPath: url.path) else { throw CocoaError(.fileWriteUnknown) }
                moved.append(url)
            } catch {
                let ns = error as NSError
                let permission = ns.code == NSFileWriteNoPermissionError || ns.code == NSFileReadNoPermissionError
                failures.append(.init(url: url, kind: permission ? .permission : .other))
            }
        }
        return .init(moved: moved, failures: failures)
    }
}
