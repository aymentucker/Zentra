import XCTest
@testable import Zentra

final class ApplicationManagerTests: XCTestCase {
    func testProtectedApplicationCannotBeRemoved() async {
        let app = InstalledApplication(url: URL(fileURLWithPath: "/System/Applications/Test.app"), name: "Test", bundleIdentifier: "com.test.system", version: "1", appBytes: 1, modifiedAt: nil, safety: .protected)
        let preview = ApplicationRemovalPreview(application: app, artifacts: [])
        let result = await ApplicationRemovalExecutor().execute(preview: preview, includeArtifacts: [])
        XCTAssertTrue(result.moved.isEmpty)
        XCTAssertEqual(result.failed, [app.url])
    }

    func testRemovalPreviewTotalsApplicationAndArtifacts() {
        let app = InstalledApplication(url: URL(fileURLWithPath: "/Applications/Test.app"), name: "Test", bundleIdentifier: "com.test.app", version: "1", appBytes: 100, modifiedAt: nil, safety: .review)
        let artifact = ApplicationArtifact(url: URL(fileURLWithPath: "/tmp/cache"), kind: .caches, bytes: 40, confidence: 1)
        let preview = ApplicationRemovalPreview(application: app, artifacts: [artifact])
        XCTAssertEqual(preview.totalBytes, 140)
    }

    func testArtifactKindsCoverExpectedLeftovers() {
        XCTAssertEqual(Set(ApplicationArtifactKind.allCases), Set([.applicationSupport, .caches, .preferences, .savedState, .logs, .containers, .groupContainers]))
    }
}
