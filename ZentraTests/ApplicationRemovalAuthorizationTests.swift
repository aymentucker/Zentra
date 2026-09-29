import XCTest
import ServiceManagement
@testable import Zentra

@MainActor
final class ApplicationRemovalAuthorizationTests: XCTestCase {
    func testServiceStatusMapping() {
        XCTAssertEqual(ApplicationRemovalAuthorization.map(.enabled), .enabled)
        XCTAssertEqual(ApplicationRemovalAuthorization.map(.requiresApproval), .requiresApproval)
        XCTAssertEqual(ApplicationRemovalAuthorization.map(.notRegistered), .notRegistered)
        XCTAssertEqual(ApplicationRemovalAuthorization.map(.notFound), .unavailable)
    }
}
