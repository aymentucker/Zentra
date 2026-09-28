import XCTest
@testable import Zentra

private final class FakeCleanupMover: CleanupMoving, @unchecked Sendable {
    var existing: Set<URL>
    init(existing: Set<URL>) { self.existing = existing }

    func moveRecoverably(_ url: URL) throws -> URL {
        let destination = URL(fileURLWithPath: "/recovery").appendingPathComponent(url.lastPathComponent)
        existing.remove(url)
        existing.insert(destination)
        return destination
    }

    func exists(_ url: URL) -> Bool { existing.contains(url) }
}

final class CleanupExecutorTests: XCTestCase {
    func testExecutorMovesAndVerifiesPlannedItem() async {
        let source = URL(fileURLWithPath: "/fixture/cache.bin")
        let mover = FakeCleanupMover(existing: [source])
        let plan = CleanupPlan(id: UUID(), createdAt: Date(), items: [
            CleanupPlanItem(id: source, url: source, size: 128, category: .cache, reason: "Test")
        ])

        let report = await CleanupExecutor(mover: mover).execute(plan)
        XCTAssertEqual(report.succeededCount, 1)
        XCTAssertEqual(report.failedCount, 0)
        XCTAssertEqual(report.processedBytes, 128)
    }

    func testExecutorReportsMissingSource() async {
        let source = URL(fileURLWithPath: "/fixture/missing.bin")
        let mover = FakeCleanupMover(existing: [])
        let plan = CleanupPlan(id: UUID(), createdAt: Date(), items: [
            CleanupPlanItem(id: source, url: source, size: 64, category: .cache, reason: "Test")
        ])

        let report = await CleanupExecutor(mover: mover).execute(plan)
        XCTAssertEqual(report.succeededCount, 0)
        XCTAssertEqual(report.failedCount, 1)
        XCTAssertEqual(report.processedBytes, 0)
    }
}
