import XCTest
@testable import Zentra

final class StorageClassifierTests: XCTestCase {
    private let classifier = StorageClassifier()

    func testMediaAndDocumentClassification() {
        XCTAssertEqual(classifier.category(for: URL(fileURLWithPath: "/Users/me/Pictures/a.jpg")), .images)
        XCTAssertEqual(classifier.category(for: URL(fileURLWithPath: "/Users/me/Movies/a.mp4")), .video)
        XCTAssertEqual(classifier.category(for: URL(fileURLWithPath: "/Users/me/Documents/a.pdf")), .documents)
        XCTAssertEqual(classifier.category(for: URL(fileURLWithPath: "/Users/me/Downloads/a.zip")), .archives)
    }

    func testDeveloperPathClassificationWins() {
        XCTAssertEqual(classifier.category(for: URL(fileURLWithPath: "/Users/me/Library/Developer/Xcode/a.db")), .developer)
    }
}
