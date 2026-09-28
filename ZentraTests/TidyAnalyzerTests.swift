import XCTest
@testable import Zentra

final class TidyAnalyzerTests:XCTestCase {
 func testCategoriesTopLevelFiles() async throws {
  let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true);defer{try? FileManager.default.removeItem(at:root)}
  try Data("x".utf8).write(to:root.appendingPathComponent("photo.jpg"));try Data("x".utf8).write(to:root.appendingPathComponent("archive.zip"));try Data("x".utf8).write(to:root.appendingPathComponent("installer.dmg"))
  let result=try await TidyAnalyzer().analyze(folder:root)
  XCTAssertEqual(Set(result.items.map(\.category)),Set([.images,.archives,.installers]))
 }
}
