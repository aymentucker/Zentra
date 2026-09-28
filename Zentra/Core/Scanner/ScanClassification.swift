import Foundation

enum ScanCategory: String, CaseIterable, Hashable, Sendable {
    case cache, logs, temporary, developer, creator, userData, other
}

struct ClassifiedScanItem: Identifiable, Sendable {
    let file: ScannedFile
    let category: ScanCategory
    let safety: ScanSafetyAssessment

    var id: URL { file.id }
}

struct ScanClassifier: Sendable {
    private let safetyPolicy = ScanSafetyPolicy()

    func classify(_ file: ScannedFile) -> ClassifiedScanItem {
        let path = file.url.standardizedFileURL.path
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path
        let relative = path.hasPrefix(home) ? String(path.dropFirst(home.count)) : path
        let lower = relative.lowercased()

        let category: ScanCategory
        if lower.hasPrefix("/library/caches/") || lower == "/library/caches" {
            category = .cache
        } else if lower.hasPrefix("/library/logs/") || lower == "/library/logs" {
            category = .logs
        } else if lower.hasPrefix("/.cache/") || lower == "/.cache" || lower.contains("/tmp/") {
            category = .temporary
        } else if isDeveloperDisposablePath(lower) {
            category = .developer
        } else if isCreatorCachePath(lower) {
            category = .creator
        } else if lower.hasPrefix("/documents/") || lower.hasPrefix("/desktop/") || lower.hasPrefix("/pictures/") || lower.hasPrefix("/movies/") || lower.hasPrefix("/music/") {
            category = .userData
        } else {
            category = .other
        }

        var safety = safetyPolicy.assess(file.url)
        if safety.level != .protected {
            switch category {
            case .cache:
                safety = cacheAssessment(file)
            case .logs:
                safety = logAssessment(file)
            case .temporary:
                safety = ScanSafetyAssessment(level: .review, reason: "Potentially disposable data that requires review")
            case .developer:
                safety = developerAssessment(file, relativePath: lower)
            case .creator:
                safety = creatorAssessment(file, relativePath: lower)
            case .userData:
                safety = ScanSafetyAssessment(level: .protected, reason: "Personal user content")
            case .other:
                break
            }
        }

        return ClassifiedScanItem(file: file, category: category, safety: safety)
    }

    private func cacheAssessment(_ file: ScannedFile) -> ScanSafetyAssessment {
        guard !file.isDirectory else {
            return ScanSafetyAssessment(level: .review, reason: "Cache container; review contents instead")
        }
        guard isOldEnough(file.modifiedAt, days: 7) else {
            return ScanSafetyAssessment(level: .review, reason: "Recently used cache")
        }
        return ScanSafetyAssessment(level: .safe, reason: "User cache older than 7 days")
    }

    private func logAssessment(_ file: ScannedFile) -> ScanSafetyAssessment {
        guard !file.isDirectory else {
            return ScanSafetyAssessment(level: .review, reason: "Log container; review contents instead")
        }
        let name = file.url.lastPathComponent.lowercased()
        if name.contains("crash") || name.contains("diagnostic") || name.contains("panic") {
            return ScanSafetyAssessment(level: .review, reason: "Diagnostic log may help troubleshoot problems")
        }
        guard isOldEnough(file.modifiedAt, days: 14) else {
            return ScanSafetyAssessment(level: .review, reason: "Recent log may still be useful")
        }
        return ScanSafetyAssessment(level: .safe, reason: "Ordinary user log older than 14 days")
    }

    private func isDeveloperDisposablePath(_ path: String) -> Bool {
        path.contains("/library/developer/xcode/deriveddata/") ||
        path.contains("/.gradle/caches/") ||
        path.contains("/.pub-cache/")
    }

    private func isCreatorCachePath(_ path: String) -> Bool {
        path.contains("/library/caches/adobe/") ||
        path.contains("/davinci resolve/cacheclip/")
    }

    private func developerAssessment(_ file: ScannedFile, relativePath: String) -> ScanSafetyAssessment {
        guard !file.isDirectory else {
            return ScanSafetyAssessment(level: .review, reason: "Developer cache container; review contents instead")
        }
        guard isDeveloperDisposablePath(relativePath) else {
            return ScanSafetyAssessment(level: .protected, reason: "Developer project or archive data is not a known disposable cache")
        }
        guard isOldEnough(file.modifiedAt, days: 3) else {
            return ScanSafetyAssessment(level: .review, reason: "Recently used developer cache")
        }
        return ScanSafetyAssessment(level: .safe, reason: "Known rebuildable developer cache older than 3 days")
    }

    private func creatorAssessment(_ file: ScannedFile, relativePath: String) -> ScanSafetyAssessment {
        guard !file.isDirectory else {
            return ScanSafetyAssessment(level: .review, reason: "Creator cache container; review contents instead")
        }
        guard isCreatorCachePath(relativePath) else {
            return ScanSafetyAssessment(level: .protected, reason: "Creator project or source media is protected")
        }
        guard isOldEnough(file.modifiedAt, days: 7) else {
            return ScanSafetyAssessment(level: .review, reason: "Recently used creator cache")
        }
        return ScanSafetyAssessment(level: .safe, reason: "Known creator cache older than 7 days")
    }

    private func isOldEnough(_ date: Date?, days: Int) -> Bool {
        guard let date else { return false }
        return date <= Date().addingTimeInterval(-Double(days) * 86_400)
    }

    func classify(_ summary: ScanSummary) -> [ClassifiedScanItem] {
        summary.files.map(classify)
    }
}

struct ScanTargetPolicy: Sendable {
    func smartCareTargets() -> [ScanTarget] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            ScanTarget(url: home.appendingPathComponent("Library/Caches"), displayName: "User Caches"),
            ScanTarget(url: home.appendingPathComponent("Library/Logs"), displayName: "User Logs")
        ].filter { FileManager.default.fileExists(atPath: $0.url.path) }
    }
}
