import XCTest
@testable import Zentra

final class WorkspaceCleanupCatalogTests: XCTestCase {
    func testProtectedHighRiskLocationsAreNeverSafe() {
        let locations = WorkspaceCleanupCatalog().locations()
        XCTAssertEqual(locations.first(where: { $0.id == "xcode-archives" })?.safety, .protected)
        XCTAssertEqual(locations.first(where: { $0.id == "docker" })?.safety, .protected)
    }

    func testCatalogSeparatesDeveloperAndCreatorGroups() {
        let locations = WorkspaceCleanupCatalog().locations()
        XCTAssertTrue(locations.contains { !$0.group.isCreator })
        XCTAssertTrue(locations.contains { $0.group.isCreator })
        XCTAssertTrue(locations.filter { $0.group.isCreator }.allSatisfy { [.adobe, .davinci, .finalCut].contains($0.group) })
    }

    func testKnownSafeLocationsDoNotPointAtProjectFolders() {
        let safe = WorkspaceCleanupCatalog().locations().filter { $0.safety == .safe }
        XCTAssertFalse(safe.contains { $0.url.path.contains("/Documents/") || $0.url.path.contains("/Desktop/") || $0.url.path.contains("/Movies/") })
    }
}
