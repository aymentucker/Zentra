import XCTest
@testable import Zentra

final class ScanClassificationTests: XCTestCase {
    private let classifier = ScanClassifier()
    private let home = FileManager.default.homeDirectoryForCurrentUser

    func testRecentCacheRequiresReview() {
        let url = home.appendingPathComponent("Library/Caches/com.example/recent.bin")
        let file = ScannedFile(id: url, url: url, size: 10, isDirectory: false, modifiedAt: Date())
        XCTAssertEqual(classifier.classify(file).safety.level, .review)
    }

    func testOldCacheCanBeSafe() {
        let url = home.appendingPathComponent("Library/Caches/com.example/old.bin")
        let old = Date().addingTimeInterval(-8 * 86_400)
        let file = ScannedFile(id: url, url: url, size: 10, isDirectory: false, modifiedAt: old)
        XCTAssertEqual(classifier.classify(file).safety.level, .safe)
    }

    func testRecentLogRequiresReview() {
        let url = home.appendingPathComponent("Library/Logs/example.log")
        let file = ScannedFile(id: url, url: url, size: 10, isDirectory: false, modifiedAt: Date())
        XCTAssertEqual(classifier.classify(file).safety.level, .review)
    }

    func testDiagnosticLogRequiresReviewEvenWhenOld() {
        let url = home.appendingPathComponent("Library/Logs/crash-diagnostic.log")
        let old = Date().addingTimeInterval(-30 * 86_400)
        let file = ScannedFile(id: url, url: url, size: 10, isDirectory: false, modifiedAt: old)
        XCTAssertEqual(classifier.classify(file).safety.level, .review)
    }
}
