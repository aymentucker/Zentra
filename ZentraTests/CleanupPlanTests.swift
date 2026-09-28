import XCTest
@testable import Zentra

final class CleanupPlanTests: XCTestCase {
    private func item(path: String, level: ScanSafetyLevel, size: Int64 = 10) -> ClassifiedScanItem {
        let url = URL(fileURLWithPath: path)
        return ClassifiedScanItem(
            file: ScannedFile(id: url, url: url, size: size, isDirectory: false, modifiedAt: nil),
            category: .cache,
            safety: ScanSafetyAssessment(level: level, reason: "Test")
        )
    }

    func testBuildAcceptsSafeItems() throws {
        let plan = try CleanupPlanBuilder().build(from: [item(path: "/tmp/a", level: .safe, size: 42)])
        XCTAssertEqual(plan.itemCount, 1)
        XCTAssertEqual(plan.totalBytes, 42)
    }

    func testBuildRejectsProtectedItem() {
        XCTAssertThrowsError(try CleanupPlanBuilder().build(from: [item(path: "/System/a", level: .protected)]))
    }

    func testBuildRejectsReviewItem() {
        XCTAssertThrowsError(try CleanupPlanBuilder().build(from: [item(path: "/tmp/a", level: .review)]))
    }

    func testBuildRejectsEmptySelection() {
        XCTAssertThrowsError(try CleanupPlanBuilder().build(from: []))
    }

    func testBuildDeduplicatesURLs() throws {
        let value = item(path: "/tmp/a", level: .safe, size: 20)
        let plan = try CleanupPlanBuilder().build(from: [value, value])
        XCTAssertEqual(plan.itemCount, 1)
        XCTAssertEqual(plan.totalBytes, 20)
    }

    func testBuildFromCompactCandidates() throws {
        let classified = item(path: "/tmp/candidate", level: .safe, size: 64)
        let plan = try CleanupPlanBuilder().build(from: [CleanupCandidate(classified)])
        XCTAssertEqual(plan.itemCount, 1)
        XCTAssertEqual(plan.totalBytes, 64)
    }
}

