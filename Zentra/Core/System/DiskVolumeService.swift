import Foundation

struct DiskVolumeSnapshot: Equatable, Sendable {
    let name: String
    let totalBytes: Int64
    let availableBytes: Int64

    var usedBytes: Int64 { max(0, totalBytes - availableBytes) }
    var usedFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return min(max(Double(usedBytes) / Double(totalBytes), 0), 1)
    }
}

protocol DiskVolumeProviding: Sendable {
    func systemVolume() throws -> DiskVolumeSnapshot
}

struct DiskVolumeService: DiskVolumeProviding {
    func systemVolume() throws -> DiskVolumeSnapshot {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let resourceValues = try? home.resourceValues(forKeys: [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ])

        let attributes = try FileManager.default.attributesOfFileSystem(forPath: home.path)

        let resourceTotal = Int64(resourceValues?.volumeTotalCapacity ?? 0)
        let resourceAvailable = resourceValues?.volumeAvailableCapacityForImportantUsage ?? 0
        let attributeTotal = (attributes[.systemSize] as? NSNumber)?.int64Value ?? 0
        let attributeFree = (attributes[.systemFreeSize] as? NSNumber)?.int64Value ?? 0

        let total = resourceTotal > 0 ? resourceTotal : attributeTotal
        let available = resourceAvailable > 0 ? resourceAvailable : attributeFree

        guard total > 0 else {
            throw DiskVolumeError.capacityUnavailable
        }

        return DiskVolumeSnapshot(
            name: resourceValues?.volumeName ?? "Macintosh HD",
            totalBytes: total,
            availableBytes: min(max(0, available), total)
        )
    }
}

enum DiskVolumeError: LocalizedError {
    case capacityUnavailable

    var errorDescription: String? { "Unable to read disk capacity." }
}

@MainActor
final class DiskVolumeModel: ObservableObject {
    @Published private(set) var snapshot: DiskVolumeSnapshot?
    @Published private(set) var error: String?
    @Published private(set) var isLoading = false

    private let service: any DiskVolumeProviding

    init(service: any DiskVolumeProviding = DiskVolumeService()) {
        self.service = service
    }

    func refresh() {
        isLoading = true
        defer { isLoading = false }

        do {
            snapshot = try service.systemVolume()
            error = nil
        } catch {
            snapshot = nil
            self.error = error.localizedDescription
        }
    }
}
