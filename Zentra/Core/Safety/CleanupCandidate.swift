import Foundation

/// Compact representation retained for selectable safe results.
/// Review/protected items remain preview-only and can never enter a plan through this type.
struct CleanupCandidate: Identifiable, Hashable, Sendable {
    let url: URL
    let size: Int64
    let category: ScanCategory
    let reason: String

    var id: URL { url }

    init(_ item: ClassifiedScanItem) {
        precondition(item.safety.level == .safe, "Only safe items may become cleanup candidates")
        url = item.file.url
        size = item.file.size
        category = item.category
        reason = item.safety.reason
    }
}
