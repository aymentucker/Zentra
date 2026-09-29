import XCTest
@testable import Zentra

final class AuthorizedApplicationRemovalPolicyTests: XCTestCase {
    func testRejectsArbitraryPaths() {
        XCTAssertFalse(AuthorizedApplicationRemovalPolicy.validateCandidate(URL(fileURLWithPath: "/tmp/Fake.app"), currentApplicationURL: nil))
        XCTAssertFalse(AuthorizedApplicationRemovalPolicy.validateCandidate(URL(fileURLWithPath: "/Applications/Folder/Fake.app"), currentApplicationURL: nil))
        XCTAssertFalse(AuthorizedApplicationRemovalPolicy.validateCandidate(URL(fileURLWithPath: "/Applications/not-an-app.txt"), currentApplicationURL: nil))
    }

    func testRejectsMissingApplicationEvenUnderApprovedRoot() {
        XCTAssertFalse(AuthorizedApplicationRemovalPolicy.validateCandidate(
            URL(fileURLWithPath: "/Applications/ZentraDefinitelyMissing.app"),
            currentApplicationURL: nil
        ))
    }

    func testRejectsCurrentApplication() {
        let current = Bundle.main.bundleURL
        XCTAssertFalse(AuthorizedApplicationRemovalPolicy.validateCandidate(current, currentApplicationURL: current))
    }
}
