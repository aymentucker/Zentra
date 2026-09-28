import XCTest
@testable import Zentra

final class SmartCareTests: XCTestCase {
    func testHealthScoreStaysWithinBounds() {
        let cleanup = ScanReviewSnapshot(groups: [:], counts: [:], bytes: [:], totalBytes: 0, safetyCounts: [:], safetyBytes: [:], safeCandidates: [])
        let workspace = SmartCareWorkspaceSummary(safeBytes: 0, reviewBytes: 0, protectedBytes: 0, safeCount: 0, reviewCount: 0, protectedCount: 0)
        let apps = ApplicationInventory(applications: [], totalBytes: 0)
        let memory = MemorySnapshot(total: 100, used: 20, available: 80, pressure: 0.2)
        let performance = PerformanceSnapshot(cpuPercent: 10, memory: memory, uptime: 10, processes: [], startupItems: [], capturedAt: Date())
        let summary = SmartCareSummary(cleanup: cleanup, workspace: workspace, applications: apps, performance: performance, completedAt: Date())
        XCTAssertEqual(summary.healthScore, 100)
    }

    func testSummaryAggregatesSafetyTotals() {
        let cleanup = ScanReviewSnapshot(groups: [:], counts: [:], bytes: [:], totalBytes: 30, safetyCounts: [.safe: 1, .review: 2, .protected: 1], safetyBytes: [.safe: 10, .review: 15, .protected: 5], safeCandidates: [])
        let workspace = SmartCareWorkspaceSummary(safeBytes: 20, reviewBytes: 10, protectedBytes: 7, safeCount: 2, reviewCount: 1, protectedCount: 1)
        let apps = ApplicationInventory(applications: [], totalBytes: 0)
        let memory = MemorySnapshot(total: 100, used: 20, available: 80, pressure: 0.2)
        let performance = PerformanceSnapshot(cpuPercent: 10, memory: memory, uptime: 10, processes: [], startupItems: [], capturedAt: Date())
        let summary = SmartCareSummary(cleanup: cleanup, workspace: workspace, applications: apps, performance: performance, completedAt: Date())
        XCTAssertEqual(summary.safeBytes, 30); XCTAssertEqual(summary.reviewBytes, 25); XCTAssertEqual(summary.protectedBytes, 12)
        XCTAssertEqual(summary.safeCount, 3); XCTAssertEqual(summary.reviewCount, 3); XCTAssertEqual(summary.protectedCount, 2)
    }
}
