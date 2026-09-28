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
        let url = URL(fileURLWithPath: "/")
        let values = try url.resourceValues(forKeys: [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ])

        let total = Int64(values.volumeTotalCapacity ?? 0)
        let available = values.volumeAvailableCapacityForImportantUsage ?? 0

        return DiskVolumeSnapshot(
            name: values.volumeName ?? "Macintosh HD",
            totalBytes: total,
            availableBytes: max(0, available)
        )
    }
}

@MainActor
final class DiskVolumeModel: ObservableObject {
    @Published private(set) var snapshot: DiskVolumeSnapshot?
    @Published private(set) var error: String?

    private let service: any DiskVolumeProviding

    init(service: any DiskVolumeProviding = DiskVolumeService()) {
        self.service = service
    }

    func refresh() {
        do {
            snapshot = try service.systemVolume()
            error = nil
        } catch {
            snapshot = nil
            self.error = error.localizedDescription
        }
    }
}
