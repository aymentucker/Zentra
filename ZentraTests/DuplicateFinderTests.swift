import XCTest
@testable import Zentra

final class DuplicateFinderTests:XCTestCase {
 func testFinderUsesContentHashNotFilename() async throws {
  let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true);defer{try? FileManager.default.removeItem(at:root)}
  let data=Data(repeating:7,count:1_100_000);try data.write(to:root.appendingPathComponent("one.bin"));try data.write(to:root.appendingPathComponent("different-name.bin"))
  let result=try await DuplicateFinder().find(roots:[root])
  XCTAssertEqual(result.groups.count,1);XCTAssertEqual(result.groups[0].files.count,2)
 }
 func testDifferentContentSameSizeIsNotDuplicate() async throws {
  let root=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true);defer{try? FileManager.default.removeItem(at:root)}
  try Data(repeating:1,count:1_100_000).write(to:root.appendingPathComponent("a"));try Data(repeating:2,count:1_100_000).write(to:root.appendingPathComponent("b"))
  let result=try await DuplicateFinder().find(roots:[root]);XCTAssertTrue(result.groups.isEmpty)
 }
}
