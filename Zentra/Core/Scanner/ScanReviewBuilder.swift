import Foundation

struct ScanReviewBuilder: Sendable {
    let previewLimit: Int

    init(previewLimit: Int = 30) {
        self.previewLimit = max(1, previewLimit)
    }

    func build(_ summary: ScanSummary) -> ScanReviewSnapshot {
        let classifier = ScanClassifier()
        var groups: [ScanCategory: [ClassifiedScanItem]] = [:]
        var counts: [ScanCategory: Int] = [:]
        var bytes: [ScanCategory: Int64] = [:]
        var safetyCounts: [ScanSafetyLevel: Int] = [:]
        var safetyBytes: [ScanSafetyLevel: Int64] = [:]
        var candidates: [CleanupCandidate] = []
        var totalBytes: Int64 = 0

        for file in summary.files {
            let item = classifier.classify(file)
            counts[item.category, default: 0] += 1
            bytes[item.category, default: 0] += file.size
            safetyCounts[item.safety.level, default: 0] += 1
            safetyBytes[item.safety.level, default: 0] += file.size
            totalBytes += file.size

            if item.safety.level == .safe { candidates.append(CleanupCandidate(item)) }

            var preview = groups[item.category, default: []]
            if preview.count < previewLimit {
                preview.append(item)
                preview.sort { $0.file.size > $1.file.size }
            } else if let smallest = preview.last, file.size > smallest.file.size {
                preview[preview.count - 1] = item
                preview.sort { $0.file.size > $1.file.size }
            }
            groups[item.category] = preview
        }

        return ScanReviewSnapshot(
            groups: groups,
            counts: counts,
            bytes: bytes,
            totalBytes: totalBytes,
            safetyCounts: safetyCounts,
            safetyBytes: safetyBytes,
            safeCandidates: candidates
        )
    }
}
