import Foundation

enum CleanupSourceKind: String, CaseIterable, Identifiable, Sendable {
    case userCaches, applicationLogs, developer, creator
    var id: String { rawValue }
}

struct CleanupSource: Identifiable, Sendable {
    let kind: CleanupSourceKind
    let targets: [ScanTarget]
    var id: CleanupSourceKind { kind }
}

struct CleanupSourceCatalog: Sendable {
    func availableSources() -> [CleanupSource] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let fm = FileManager.default

        func targets(_ candidates: [(String, String)]) -> [ScanTarget] {
            candidates.compactMap { relative, name in
                let url = home.appendingPathComponent(relative)
                guard fm.fileExists(atPath: url.path) else { return nil }
                return ScanTarget(url: url, displayName: name)
            }
        }

        return [
            CleanupSource(kind: .userCaches, targets: targets([
                ("Library/Caches", "User Caches")
            ])),
            CleanupSource(kind: .applicationLogs, targets: targets([
                ("Library/Logs", "Application Logs")
            ])),
            CleanupSource(kind: .developer, targets: targets([
                ("Library/Developer/Xcode/DerivedData", "Xcode Derived Data"),
                (".gradle/caches", "Gradle Caches"),
                (".pub-cache", "Dart Pub Cache")
            ])),
            CleanupSource(kind: .creator, targets: targets([
                ("Library/Caches/Adobe", "Adobe Caches"),
                ("Library/Application Support/Blackmagic Design/DaVinci Resolve/CacheClip", "DaVinci Cache")
            ]))
        ]
    }
}
