import Foundation

/// Shared request contract for the privileged application-removal service.
///
/// The daemon implementation must independently revalidate every field.
/// This type deliberately contains no arbitrary destination, command, flags,
/// recursive-delete option, or generic file-operation surface.
struct AuthorizedApplicationRemovalRequest: Codable, Sendable, Equatable {
    let canonicalApplicationPath: String
    let expectedBundleIdentifier: String?
}

enum AuthorizedApplicationRemovalPolicy {
    static let approvedRoot = URL(fileURLWithPath: "/Applications", isDirectory: true).standardizedFileURL

    static func validateCandidate(_ url: URL, currentApplicationURL: URL? = Bundle.main.bundleURL) -> Bool {
        let candidate = url.resolvingSymlinksInPath().standardizedFileURL
        guard candidate.pathExtension.lowercased() == "app" else { return false }
        guard candidate.deletingLastPathComponent() == approvedRoot else { return false }
        if let currentApplicationURL {
            let current = currentApplicationURL.resolvingSymlinksInPath().standardizedFileURL
            guard candidate != current else { return false }
        }
        guard FileManager.default.fileExists(atPath: candidate.path) else { return false }
        guard Bundle(url: candidate) != nil else { return false }
        return true
    }

    static func makeRequest(for application: InstalledApplication) -> AuthorizedApplicationRemovalRequest? {
        let canonical = application.url.resolvingSymlinksInPath().standardizedFileURL
        guard application.safety != .protected, validateCandidate(canonical) else { return nil }
        return .init(canonicalApplicationPath: canonical.path, expectedBundleIdentifier: application.bundleIdentifier)
    }
}
