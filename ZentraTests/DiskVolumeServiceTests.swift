import XCTest
@testable import Zentra

final class DiskVolumeServiceTests: XCTestCase {
    func testSystemVolumeReturnsSaneCapacity() throws {
        let snapshot = try DiskVolumeService().systemVolume()
        XCTAssertGreaterThan(snapshot.totalBytes, 0)
        XCTAssertGreaterThanOrEqual(snapshot.availableBytes, 0)
        XCTAssertLessThanOrEqual(snapshot.availableBytes, snapshot.totalBytes)
        XCTAssertTrue((0...1).contains(snapshot.usedFraction))
    }
}
