import XCTest
@testable import Zentra

final class ScanReviewSnapshotTests: XCTestCase {
    func testLargeScanKeepsBoundedPreviewButAllSafeCandidates() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let old = Date().addingTimeInterval(-10 * 86_400)
        let files = (0..<2_000).map { index in
            let url = home.appendingPathComponent("Library/Caches/test/file-\(index)")
            return ScannedFile(id: url, url: url, size: Int64(index + 1), isDirectory: false, modifiedAt: old)
        }
        let summary = ScanSummary(files: files, totalBytes: files.reduce(0) { $0 + $1.size }, skippedItems: 0)
        let snapshot = ScanReviewBuilder(previewLimit: 30).build(summary)

        XCTAssertEqual(snapshot.counts[.cache], 2_000)
        XCTAssertEqual(snapshot.groups[.cache]?.count, 30)
        XCTAssertEqual(snapshot.safeCandidates.count, 2_000)
        XCTAssertEqual(snapshot.count(for: .safe), 2_000)
        XCTAssertEqual(snapshot.bytes(for: .safe), summary.totalBytes)
        XCTAssertEqual(snapshot.groups[.cache]?.first?.file.size, 2_000)
    }

    func testReviewItemsNeverBecomeCleanupCandidates() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let url = home.appendingPathComponent("Library/Caches/test/recent")
        let file = ScannedFile(id: url, url: url, size: 50, isDirectory: false, modifiedAt: Date())
        let snapshot = ScanReviewBuilder().build(ScanSummary(files: [file], totalBytes: 50, skippedItems: 0))

        XCTAssertEqual(snapshot.count(for: .review), 1)
        XCTAssertTrue(snapshot.safeCandidates.isEmpty)
    }
}
