import XCTest
@testable import Zentra

final class PerformanceMonitorTests: XCTestCase {
    func testSnapshotReturnsSaneMemoryAndCPU() async {
        let snapshot = await PerformanceMonitor().snapshot()
        XCTAssertGreaterThan(snapshot.memory.total, 0)
        XCTAssertLessThanOrEqual(snapshot.memory.used, snapshot.memory.total)
        XCTAssertGreaterThanOrEqual(snapshot.cpuPercent, 0)
        XCTAssertLessThanOrEqual(snapshot.cpuPercent, 100)
    }

    func testStartupScannerReturnsOnlyPlists() {
        let items = StartupItemScanner().scan()
        XCTAssertTrue(items.allSatisfy { $0.url.pathExtension == "plist" })
    }
}
