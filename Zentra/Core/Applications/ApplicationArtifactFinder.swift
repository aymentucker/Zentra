import Foundation

actor ApplicationArtifactFinder {
    private let fm = FileManager.default

    func preview(for app: InstalledApplication) async -> ApplicationRemovalPreview {
        guard let id = app.bundleIdentifier, !id.isEmpty else {
            return ApplicationRemovalPreview(application: app, artifacts: [])
        }
        let library = fm.homeDirectoryForCurrentUser.appendingPathComponent("Library", isDirectory: true)
        let exact: [(ApplicationArtifactKind, URL)] = [
            (.applicationSupport, library.appendingPathComponent("Application Support/\(id)")),
            (.caches, library.appendingPathComponent("Caches/\(id)")),
            (.preferences, library.appendingPathComponent("Preferences/\(id).plist")),
            (.savedState, library.appendingPathComponent("Saved Application State/\(id).savedState")),
            (.logs, library.appendingPathComponent("Logs/\(id)")),
            (.containers, library.appendingPathComponent("Containers/\(id)"))
        ]
        var artifacts: [ApplicationArtifact] = []
        for (kind, url) in exact where fm.fileExists(atPath: url.path) {
            artifacts.append(ApplicationArtifact(url: url, kind: kind, bytes: allocatedSize(of: url), confidence: 1))
        }

        // Group containers are only included when their directory name contains
        // the exact bundle identifier. They remain reviewable, never silently removed.
        let groups = library.appendingPathComponent("Group Containers", isDirectory: true)
        if let children = try? fm.contentsOfDirectory(at: groups, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
            for url in children where url.lastPathComponent == id || url.lastPathComponent.hasSuffix(".\(id)") {
                artifacts.append(ApplicationArtifact(url: url, kind: .groupContainers, bytes: allocatedSize(of: url), confidence: 0.9))
            }
        }
        return ApplicationRemovalPreview(application: app, artifacts: artifacts.sorted { $0.bytes > $1.bytes })
    }

    private func allocatedSize(of url: URL) -> Int64 {
        var isDirectory: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return 0 }
        if !isDirectory.boolValue {
            let v = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey])
            return Int64(v?.totalFileAllocatedSize ?? v?.fileAllocatedSize ?? 0)
        }
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey]
        guard let e = fm.enumerator(at: url, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles]) else { return 0 }
        var total: Int64 = 0
        while let child = e.nextObject() as? URL {
            guard let v = try? child.resourceValues(forKeys: keys), v.isSymbolicLink != true, v.isRegularFile == true else { continue }
            total += Int64(v.totalFileAllocatedSize ?? v.fileAllocatedSize ?? 0)
        }
        return total
    }
}
