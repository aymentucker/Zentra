import Foundation

actor ApplicationScanner {
    private let fm = FileManager.default

    func scan() async throws -> ApplicationInventory {
        let roots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true)
        ]
        var seen = Set<String>()
        var apps: [InstalledApplication] = []

        for root in roots where fm.fileExists(atPath: root.path) {
            let keys: Set<URLResourceKey> = [.isDirectoryKey, .isSymbolicLinkKey, .contentModificationDateKey, .totalFileAllocatedSizeKey]
            guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
            while let url = enumerator.nextObject() as? URL {
                try Task.checkCancellation()
                guard url.pathExtension.lowercased() == "app" else { continue }
                enumerator.skipDescendants()
                let canonical = url.standardizedFileURL.path
                guard seen.insert(canonical).inserted else { continue }
                if let app = application(at: url) { apps.append(app) }
            }
        }
        apps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return ApplicationInventory(applications: apps, totalBytes: apps.reduce(0) { $0 + $1.appBytes })
    }

    private func application(at url: URL) -> InstalledApplication? {
        guard let bundle = Bundle(url: url) else { return nil }
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        let bundleID = bundle.bundleIdentifier
        let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? url.deletingPathExtension().lastPathComponent
        let version = (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
        return InstalledApplication(
            url: url,
            name: name,
            bundleIdentifier: bundleID,
            version: version,
            appBytes: allocatedSize(of: url),
            modifiedAt: values?.contentModificationDate,
            safety: safety(for: url, bundleIdentifier: bundleID)
        )
    }

    private func safety(for url: URL, bundleIdentifier: String?) -> ApplicationSafety {
        let path = url.standardizedFileURL.path
        if path.hasPrefix("/System/") || path.hasPrefix("/Applications/Utilities/") { return .protected }
        if bundleIdentifier == Bundle.main.bundleIdentifier { return .protected }
        if path.hasPrefix("/Applications/") || path.hasPrefix(FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path) { return .review }
        return .protected
    }

    private func allocatedSize(of url: URL) -> Int64 {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .isSymbolicLinkKey, .totalFileAllocatedSizeKey, .fileAllocatedSizeKey]
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: Array(keys), options: [.skipsHiddenFiles]) else { return 0 }
        var total: Int64 = 0
        while let child = enumerator.nextObject() as? URL {
            guard let values = try? child.resourceValues(forKeys: keys), values.isSymbolicLink != true, values.isRegularFile == true else { continue }
            total += Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
        }
        return total
    }
}
