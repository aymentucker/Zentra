import Foundation

enum RemovalServicePolicy {
    private static let applicationsRoot = URL(fileURLWithPath: "/Applications", isDirectory: true).standardizedFileURL

    static func validate(url: URL, expectedBundleIdentifier: String?) -> Bool {
        let candidate = url.resolvingSymlinksInPath().standardizedFileURL
        guard candidate.pathExtension.lowercased() == "app" else { return false }
        guard candidate.deletingLastPathComponent() == applicationsRoot else { return false }
        guard FileManager.default.fileExists(atPath: candidate.path) else { return false }
        guard let bundle = Bundle(url: candidate) else { return false }

        if let expectedBundleIdentifier, !expectedBundleIdentifier.isEmpty {
            guard bundle.bundleIdentifier == expectedBundleIdentifier else { return false }
        }

        // Never permit Apple/system-owned application identifiers through this
        // narrow third-party app removal service.
        if bundle.bundleIdentifier?.hasPrefix("com.apple.") == true { return false }
        if bundle.bundleIdentifier == "com.zentra.app" { return false }
        return true
    }
}
