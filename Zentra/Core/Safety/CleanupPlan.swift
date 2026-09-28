import Foundation

struct CleanupPlanItem: Identifiable, Hashable, Sendable {
    let id: URL
    let url: URL
    let size: Int64
    let category: ScanCategory
    let reason: String
}

struct CleanupPlan: Sendable {
    let id: UUID
    let createdAt: Date
    let items: [CleanupPlanItem]

    var itemCount: Int { items.count }
    var totalBytes: Int64 { items.reduce(0) { $0 + $1.size } }
}

enum CleanupPlanError: LocalizedError, Equatable {
    case emptySelection
    case itemRequiresReview(URL)
    case protectedItem(URL)

    var errorDescription: String? {
        switch self {
        case .emptySelection: "No safe items were selected."
        case .itemRequiresReview(let url): "This item requires explicit review: \(url.path)"
        case .protectedItem(let url): "Protected data cannot be included: \(url.path)"
        }
    }
}

struct CleanupPlanBuilder: Sendable {
    func build(from candidates: [CleanupCandidate]) throws -> CleanupPlan {
        guard !candidates.isEmpty else { throw CleanupPlanError.emptySelection }
        let unique = Dictionary(candidates.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }).values
        let planned = unique.map { CleanupPlanItem(id: $0.id, url: $0.url, size: $0.size, category: $0.category, reason: $0.reason) }
        return CleanupPlan(id: UUID(), createdAt: Date(), items: planned.sorted { $0.size > $1.size })
    }


    func build(from items: [ClassifiedScanItem]) throws -> CleanupPlan {
        guard !items.isEmpty else { throw CleanupPlanError.emptySelection }

        let unique = Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }).values
        var planned: [CleanupPlanItem] = []
        planned.reserveCapacity(unique.count)

        for item in unique {
            switch item.safety.level {
            case .safe:
                planned.append(CleanupPlanItem(id: item.id, url: item.file.url, size: item.file.size, category: item.category, reason: item.safety.reason))
            case .review:
                throw CleanupPlanError.itemRequiresReview(item.file.url)
            case .protected:
                throw CleanupPlanError.protectedItem(item.file.url)
            }
        }

        return CleanupPlan(id: UUID(), createdAt: Date(), items: planned.sorted { $0.size > $1.size })
    }
}
