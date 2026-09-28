import Foundation

enum SmartCareModule: String, CaseIterable, Identifiable, Sendable {
    case cleanup, workspace, applications, performance
    var id: String { rawValue }
}

enum SmartCareRunState: Equatable {
    case idle, scanning(SmartCareModule), completed, cancelled, failed(String)
}

struct SmartCareWorkspaceSummary: Sendable {
    let safeBytes: Int64
    let reviewBytes: Int64
    let protectedBytes: Int64
    let safeCount: Int
    let reviewCount: Int
    let protectedCount: Int
}

struct SmartCareSummary: Sendable {
    let cleanup: ScanReviewSnapshot
    let workspace: SmartCareWorkspaceSummary
    let applications: ApplicationInventory
    let performance: PerformanceSnapshot
    let completedAt: Date

    var safeBytes: Int64 { cleanup.bytes(for: .safe) + workspace.safeBytes }
    var reviewBytes: Int64 { cleanup.bytes(for: .review) + workspace.reviewBytes }
    var protectedBytes: Int64 { cleanup.bytes(for: .protected) + workspace.protectedBytes }
    var safeCount: Int { cleanup.count(for: .safe) + workspace.safeCount }
    var reviewCount: Int { cleanup.count(for: .review) + workspace.reviewCount }
    var protectedCount: Int { cleanup.count(for: .protected) + workspace.protectedCount }

    var healthScore: Int {
        var score = 100
        if performance.cpuPercent > 80 { score -= 12 }
        if performance.memory.pressure > 0.85 { score -= 12 }
        if reviewCount > 0 { score -= min(15, reviewCount) }
        if safeBytes > 5_000_000_000 { score -= 10 }
        return max(0, score)
    }
}
