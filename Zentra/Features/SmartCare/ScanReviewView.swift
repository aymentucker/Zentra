import SwiftUI

struct ScanReviewView: View {
    let items: [ClassifiedScanItem]
    @State private var expanded: Set<ScanCategory> = []

    private var files: [ClassifiedScanItem] { items.filter { !$0.file.isDirectory } }
    private var totalBytes: Int64 { files.reduce(0) { $0 + $1.file.size } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("scan.review.title").zentraFont(20, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                    Text("scan.review.readonly").zentraFont(12).foregroundStyle(Color.zentraTextSecondary)
                }
                Spacer()
                Text(ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file))
                    .zentraFont(18, weight: .semibold).foregroundStyle(Color.zentraAccent)
            }

            ForEach(ScanCategory.allCases, id: \.self) { category in
                let categoryItems = files.filter { $0.category == category }
                if !categoryItems.isEmpty {
                    Button {
                        if expanded.contains(category) {
                            expanded.remove(category)
                        } else {
                            expanded.insert(category)
                        }
                    } label: {
                    HStack(spacing: 12) {
                        Image(systemName: expanded.contains(category) ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.zentraTextTertiary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.titleKey).zentraFont(13, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                            Text("\(categoryItems.count) · \(ByteCountFormatter.string(fromByteCount: categoryItems.reduce(0) { $0 + $1.file.size }, countStyle: .file))")
                                .zentraFont(11).foregroundStyle(Color.zentraTextTertiary)
                        }
                        Spacer()
                        SafetyBadge(level: categoryItems.map(\.safety.level).max() ?? .review)
                    }
                    .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)

                    if expanded.contains(category) {
                        VStack(spacing: 0) {
                            ForEach(categoryItems.sorted { $0.file.size > $1.file.size }.prefix(50)) { item in
                                HStack(spacing: 10) {
                                    Image(systemName: item.safety.level == .protected ? "lock.fill" : "doc")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.zentraTextTertiary)
                                        .frame(width: 14)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.file.url.lastPathComponent)
                                            .zentraFont(11.5, weight: .medium)
                                            .foregroundStyle(Color.zentraTextSecondary)
                                            .lineLimit(1)
                                        Text(item.safety.reason)
                                            .zentraFont(10)
                                            .foregroundStyle(Color.zentraTextTertiary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text(ByteCountFormatter.string(fromByteCount: item.file.size, countStyle: .file))
                                        .zentraFont(10.5)
                                        .foregroundStyle(Color.zentraTextTertiary)
                                    SafetyBadge(level: item.safety.level)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        .padding(.leading, 22)
                    }
                    if category != ScanCategory.allCases.last { Divider().overlay(Color.white.opacity(0.06)) }
                }
            }
        }
    }
}

private struct SafetyBadge: View {
    let level: ScanSafetyLevel

    var body: some View {
        Text(level.titleKey)
            .zentraFont(10, weight: .semibold)
            .foregroundStyle(level == .safe ? Color.zentraAccent : Color.zentraTextSecondary)
            .padding(.horizontal, 9).frame(height: 24)
            .background(Capsule().fill(Color.white.opacity(0.055)))
    }
}

private extension ScanCategory {
    var titleKey: LocalizedStringKey {
        switch self {
        case .cache: "scan.category.cache"
        case .logs: "scan.category.logs"
        case .temporary: "scan.category.temporary"
        case .developer: "scan.category.developer"
        case .userData: "scan.category.userData"
        case .other: "scan.category.other"
        }
    }
}

private extension ScanSafetyLevel {
    var titleKey: LocalizedStringKey {
        switch self {
        case .safe: "scan.safety.safe"
        case .review: "scan.safety.review"
        case .protected: "scan.safety.protected"
        }
    }
}
