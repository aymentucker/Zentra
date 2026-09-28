import Foundation

enum ApplicationSafety: String, CaseIterable, Sendable { case removable, review, protected }

struct InstalledApplication: Identifiable, Hashable, Sendable {
    let url: URL
    let name: String
    let bundleIdentifier: String?
    let version: String?
    let appBytes: Int64
    let modifiedAt: Date?
    let safety: ApplicationSafety
    var id: String { url.standardizedFileURL.path }
}

enum ApplicationArtifactKind: String, CaseIterable, Sendable {
    case applicationSupport, caches, preferences, savedState, logs, containers, groupContainers
}

struct ApplicationArtifact: Identifiable, Hashable, Sendable {
    let url: URL
    let kind: ApplicationArtifactKind
    let bytes: Int64
    let confidence: Double
    var id: String { url.standardizedFileURL.path }
}

struct ApplicationRemovalPreview: Sendable {
    let application: InstalledApplication
    let artifacts: [ApplicationArtifact]
    var totalBytes: Int64 { application.appBytes + artifacts.reduce(0) { $0 + $1.bytes } }
}

struct ApplicationInventory: Sendable {
    let applications: [InstalledApplication]
    let totalBytes: Int64
}
