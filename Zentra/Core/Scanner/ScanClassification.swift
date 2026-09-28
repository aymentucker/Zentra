import Foundation

enum ScanCategory: String, CaseIterable, Hashable, Sendable {
    case cache, logs, temporary, developer, userData, other
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
        } else if lower.contains("/deriveddata/") || lower.contains("/.dart_tool/") || lower.contains("/node_modules/") || lower.contains("/.gradle/") {
            category = .developer
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
            case .temporary, .developer:
                safety = ScanSafetyAssessment(level: .review, reason: "Potentially disposable data that requires review")
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
