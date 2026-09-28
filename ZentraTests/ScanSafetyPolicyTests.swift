import XCTest
@testable import Zentra

final class ScanSafetyPolicyTests: XCTestCase {
    private let policy = ScanSafetyPolicy()

    func testSystemPathIsProtected() {
        XCTAssertEqual(policy.assess(URL(fileURLWithPath: "/System/Library")).level, .protected)
    }

    func testSensitiveHomeDataIsProtected() {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Keychains")
        XCTAssertEqual(policy.assess(url).level, .protected)
    }

    func testNormalHomePathRequiresReview() {
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Downloads/example.zip")
        XCTAssertEqual(policy.assess(url).level, .review)
    }
}
