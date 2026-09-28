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

    func testOldDerivedDataIsKnownDeveloperCache() {
        let url = home.appendingPathComponent("Library/Developer/Xcode/DerivedData/App/Build/object.o")
        let old = Date().addingTimeInterval(-4 * 86_400)
        let file = ScannedFile(id: url, url: url, size: 10, isDirectory: false, modifiedAt: old)
        let result = classifier.classify(file)
        XCTAssertEqual(result.category, .developer)
        XCTAssertEqual(result.safety.level, .safe)
    }

    func testRecentDerivedDataRequiresReview() {
        let url = home.appendingPathComponent("Library/Developer/Xcode/DerivedData/App/index.db")
        let file = ScannedFile(id: url, url: url, size: 10, isDirectory: false, modifiedAt: Date())
        XCTAssertEqual(classifier.classify(file).safety.level, .review)
    }

    func testOldAdobeCacheIsCreatorCache() {
        let url = home.appendingPathComponent("Library/Caches/Adobe/example.cache")
        let old = Date().addingTimeInterval(-8 * 86_400)
        let file = ScannedFile(id: url, url: url, size: 10, isDirectory: false, modifiedAt: old)
        let result = classifier.classify(file)
        XCTAssertEqual(result.category, .cache)
        XCTAssertEqual(result.safety.level, .safe)
    }
}

