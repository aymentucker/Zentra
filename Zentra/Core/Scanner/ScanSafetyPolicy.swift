import Foundation

enum ScanSafetyLevel: Int, Comparable, Sendable {
    case safe
    case review
    case protected

    static func < (lhs: ScanSafetyLevel, rhs: ScanSafetyLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct ScanSafetyAssessment: Sendable {
    let level: ScanSafetyLevel
    let reason: String
}

struct ScanSafetyPolicy: Sendable {
    private let protectedPrefixes = [
        "/System",
        "/bin",
        "/sbin",
        "/usr",
        "/private",
        "/Library"
    ]

    func assess(_ url: URL) -> ScanSafetyAssessment {
        let path = url.standardizedFileURL.path

        if protectedPrefixes.contains(where: { path == $0 || path.hasPrefix($0 + "/") }) {
            return ScanSafetyAssessment(level: .protected, reason: "System or shared library path")
        }

        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path
        guard path == home || path.hasPrefix(home + "/") else {
            return ScanSafetyAssessment(level: .review, reason: "Outside the current user's home directory")
        }

        let relative = String(path.dropFirst(home.count))
        let protectedHomePrefixes = ["/Library/Keychains", "/Library/Mail", "/Library/Messages", "/Library/Safari"]
        if protectedHomePrefixes.contains(where: { relative == $0 || relative.hasPrefix($0 + "/") }) {
            return ScanSafetyAssessment(level: .protected, reason: "Sensitive user data")
        }

        return ScanSafetyAssessment(level: .review, reason: "User-owned path; classification required before cleanup")
    }
}
