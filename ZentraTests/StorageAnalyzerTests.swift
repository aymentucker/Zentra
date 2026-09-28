import XCTest
@testable import Zentra

final class StorageAnalyzerTests: XCTestCase {
    func testAnalyzerCountsAndCategorizesFiles() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let image = root.appendingPathComponent("photo.jpg")
        let archive = root.appendingPathComponent("backup.zip")
        try Data(repeating: 1, count: 12).write(to: image)
        try Data(repeating: 2, count: 20).write(to: archive)

        let result = try await StorageAnalyzer().analyze(roots: [root])
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.totalBytes, 32)
        XCTAssertEqual(result.categoryBytes[.images], 12)
        XCTAssertEqual(result.categoryBytes[.archives], 20)
    }

    func testLargeFilesThresholdIsOneHundredMB() {
        let big = StorageItem(url: URL(fileURLWithPath: "/tmp/big.mov"), size: 101 * 1_024 * 1_024, modifiedAt: nil, category: .video)
        let small = StorageItem(url: URL(fileURLWithPath: "/tmp/small.mov"), size: 99 * 1_024 * 1_024, modifiedAt: nil, category: .video)
        let analysis = StorageAnalysis(items: [small, big], categoryBytes: [.video: small.size + big.size], totalBytes: small.size + big.size, skippedItems: 0)
        XCTAssertEqual(analysis.largeFiles.map(\.url), [big.url])
    }

    func testTreeBuilderAggregatesImmediateFolders() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let docs = home.appendingPathComponent("Documents")
        let project = docs.appendingPathComponent("Project")
        let a = StorageItem(url: project.appendingPathComponent("a.mov"), size: 70, modifiedAt: nil, category: .video)
        let b = StorageItem(url: project.appendingPathComponent("b.mov"), size: 30, modifiedAt: nil, category: .video)
        let direct = StorageItem(url: docs.appendingPathComponent("note.pdf"), size: 10, modifiedAt: nil, category: .documents)
        let nodes = StorageTreeBuilder().children(of: docs, from: [a, b, direct])
        let folder = nodes.first { $0.isDirectory }
        XCTAssertEqual(folder?.name, "Project")
        XCTAssertEqual(folder?.totalBytes, 100)
        XCTAssertEqual(folder?.fileCount, 2)
        XCTAssertTrue(nodes.contains { !$0.isDirectory && $0.name == "note.pdf" })
    }
}

