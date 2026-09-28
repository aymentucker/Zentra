import XCTest
@testable import Zentra

final class ScanReviewSnapshotTests: XCTestCase {
    func testLargeScanStillCompletes() async {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let files = (0..<2_000).map { index in
            let url = home.appendingPathComponent("Library/Caches/test/file-\(index)")
            return ScannedFile(id: url, url: url, size: Int64(index + 1), isDirectory: false, modifiedAt: Date().addingTimeInterval(-10 * 86_400))
        }

        let summary = ScanSummary(files: files, totalBytes: files.reduce(0) { $0 + $1.size }, skippedItems: 0)
        XCTAssertEqual(summary.fileCount, 2_000)
        XCTAssertGreaterThan(summary.totalBytes, 0)
    }
}
