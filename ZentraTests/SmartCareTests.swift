import XCTest
@testable import Zentra

final class SmartCareTests: XCTestCase {
    private func makeSummary(storageUsed: Double = 0.2, memoryPressure: Double = 0.2, cpu: Double = 10, reviewCount: Int = 0) -> SmartCareSummary {
        let cleanup = ScanReviewSnapshot(groups: [:], counts: [:], bytes: [:], totalBytes: 0, safetyCounts: [.review: reviewCount], safetyBytes: [:], safeCandidates: [])
        let storage = SmartCareStorageSummary(totalBytes: 1000, availableBytes: Int64(1000 * (1 - storageUsed)))
        let workspace = SmartCareWorkspaceSummary(safeBytes: 0, reviewBytes: 0, protectedBytes: 0, safeCount: 0, reviewCount: 0, protectedCount: 0)
        let apps = ApplicationInventory(applications: [], totalBytes: 0)
        let memory = MemorySnapshot(total: 100, used: 20, available: 80, pressure: memoryPressure)
        let performance = PerformanceSnapshot(cpuPercent: cpu, memory: memory, uptime: 10, processes: [], startupItems: [], capturedAt: Date())
        return SmartCareSummary(cleanup: cleanup, storage: storage, workspace: workspace, applications: apps, performance: performance, completedAt: Date())
    }

    func testStatusReadyUnderNormalConditions() {
        XCTAssertEqual(makeSummary().status, .ready)
    }

    func testStatusRecommendsReviewForReviewItemsOrHighStorage() {
        XCTAssertEqual(makeSummary(reviewCount: 1).status, .reviewRecommended)
        XCTAssertEqual(makeSummary(storageUsed: 0.9).status, .reviewRecommended)
    }

    func testStatusNeedsAttentionForCriticalStorageOrMemory() {
        XCTAssertEqual(makeSummary(storageUsed: 0.96).status, .attention)
        XCTAssertEqual(makeSummary(memoryPressure: 0.95).status, .attention)
    }

    func testStorageSummaryCalculatesUsedSpace() {
        let storage = SmartCareStorageSummary(totalBytes: 1000, availableBytes: 250)
        XCTAssertEqual(storage.usedBytes, 750)
        XCTAssertEqual(storage.usedFraction, 0.75, accuracy: 0.001)
    }

    func testSummaryAggregatesSafetyTotals() {
        let cleanup = ScanReviewSnapshot(groups: [:], counts: [:], bytes: [:], totalBytes: 30, safetyCounts: [.safe: 1, .review: 2, .protected: 1], safetyBytes: [.safe: 10, .review: 15, .protected: 5], safeCandidates: [])
        let storage = SmartCareStorageSummary(totalBytes: 1000, availableBytes: 800)
        let workspace = SmartCareWorkspaceSummary(safeBytes: 20, reviewBytes: 10, protectedBytes: 7, safeCount: 2, reviewCount: 1, protectedCount: 1)
        let apps = ApplicationInventory(applications: [], totalBytes: 0)
        let memory = MemorySnapshot(total: 100, used: 20, available: 80, pressure: 0.2)
        let performance = PerformanceSnapshot(cpuPercent: 10, memory: memory, uptime: 10, processes: [], startupItems: [], capturedAt: Date())
        let summary = SmartCareSummary(cleanup: cleanup, storage: storage, workspace: workspace, applications: apps, performance: performance, completedAt: Date())
        XCTAssertEqual(summary.safeBytes, 30); XCTAssertEqual(summary.reviewBytes, 25); XCTAssertEqual(summary.protectedBytes, 12)
        XCTAssertEqual(summary.safeCount, 3); XCTAssertEqual(summary.reviewCount, 3); XCTAssertEqual(summary.protectedCount, 2)
    }
}
