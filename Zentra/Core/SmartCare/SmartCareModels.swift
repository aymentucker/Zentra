import Foundation

enum SmartCareModule: String, CaseIterable, Identifiable, Sendable {
    case cleanup, storage, workspace, applications, performance
    var id: String { rawValue }
}

enum SmartCareRunState: Equatable {
    case idle, scanning(SmartCareModule), completed, cancelled, failed(String)
}

struct SmartCareStorageSummary: Sendable {
    let totalBytes: Int64
    let availableBytes: Int64
    var usedBytes: Int64 { max(0, totalBytes - availableBytes) }
    var usedFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return min(1, max(0, Double(usedBytes) / Double(totalBytes)))
    }
}

enum SmartCareStatus: String, Sendable {
    case ready, reviewRecommended, attention
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
    let storage: SmartCareStorageSummary
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

    var status: SmartCareStatus {
        if storage.usedFraction >= 0.95 || performance.memory.pressure >= 0.9 { return .attention }
        if reviewCount > 0 || storage.usedFraction >= 0.85 || performance.cpuPercent >= 85 { return .reviewRecommended }
        return .ready
    }
}
