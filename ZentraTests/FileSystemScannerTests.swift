import XCTest
@testable import Zentra

final class FileSystemScannerTests: XCTestCase {
    func testScannerCountsFilesAndBytes() async throws {
        let root = try makeFixture()
        defer { try? FileManager.default.removeItem(at: root) }

        try Data(repeating: 1, count: 128).write(to: root.appendingPathComponent("a.bin"))
        let nested = root.appendingPathComponent("nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try Data(repeating: 2, count: 256).write(to: nested.appendingPathComponent("b.bin"))

        let result = try await FileSystemScanner().scan(targets: [ScanTarget(url: root)])

        XCTAssertEqual(result.files.filter { !$0.isDirectory }.count, 2)
        XCTAssertEqual(result.totalBytes, 384)
    }

    func testScannerRejectsMissingTarget() async {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            _ = try await FileSystemScanner().scan(targets: [ScanTarget(url: missing)])
            XCTFail("Expected invalid target error")
        } catch {
            XCTAssertTrue(error is ScannerError)
        }
    }

    private func makeFixture() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("ZentraScannerTests")
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
}
