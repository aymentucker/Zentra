import Foundation

struct SmartCareStorageService: Sendable {
    func snapshot() throws -> SmartCareStorageSummary {
        let url = URL(fileURLWithPath: "/System/Volumes/Data", isDirectory: true)
        let values = try url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey])
        let total = Int64(values.volumeTotalCapacity ?? 0)
        let available = values.volumeAvailableCapacityForImportantUsage ?? Int64(values.volumeAvailableCapacity ?? 0)
        return SmartCareStorageSummary(totalBytes: max(0, total), availableBytes: max(0, available))
    }
}
