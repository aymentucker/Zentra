import SwiftUI

struct ScanReviewView: View {
    let snapshot: ScanReviewSnapshot
    @State private var expanded: Set<ScanCategory> = []
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("scan.review.title").zentraFont(20, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                    Text("scan.review.readonly").zentraFont(12).foregroundStyle(Color.zentraTextSecondary)
                }
                Spacer()
                Text(ByteCountFormatter.string(fromByteCount: snapshot.totalBytes, countStyle: .file))
                    .zentraFont(18, weight: .semibold).foregroundStyle(Color.zentraAccent)
            }

            LazyVStack(spacing: 0) {
                ForEach(ScanCategory.allCases, id: \.self) { category in
                    if let categoryItems = snapshot.groups[category], !categoryItems.isEmpty {
                        categorySection(category, items: categoryItems, count: snapshot.counts[category] ?? categoryItems.count, bytes: snapshot.bytes[category] ?? 0)
                    }
                }
            }
        }
    }

    private func categorySection(_ category: ScanCategory, items: [ClassifiedScanItem], count: Int, bytes: Int64) -> some View {
        VStack(spacing: 0) {
            Button {
                if expanded.contains(category) { expanded.remove(category) }
                else { expanded.insert(category) }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.titleKey).zentraFont(13, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                        Text("\(count) · \(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))")
                            .zentraFont(11).foregroundStyle(Color.zentraTextTertiary)
                    }
                    Spacer()
                    Image(systemName: chevronName(for: category))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.zentraTextSecondary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.white.opacity(0.055)))
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded.contains(category) {
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in ScanItemRow(item: item) }
                }
                .padding(.leading, 24)

            }

            Divider().overlay(Color.white.opacity(0.06))
        }
    }

    private func chevronName(for category: ScanCategory) -> String {
        if expanded.contains(category) { return "chevron.down" }
        return layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right"
    }
}

private struct ScanItemRow: View {
    let item: ClassifiedScanItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.safety.level == .protected ? "lock.fill" : "doc")
                .font(.system(size: 10))
                .foregroundStyle(Color.zentraTextTertiary)
                .frame(width: 14)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.file.url.lastPathComponent)
                    .zentraFont(11.5, weight: .medium).foregroundStyle(Color.zentraTextSecondary).lineLimit(1)
                Text(item.safety.reason)
                    .zentraFont(10).foregroundStyle(Color.zentraTextTertiary).lineLimit(1)
            }
            Spacer(minLength: 12)
            Text(ByteCountFormatter.string(fromByteCount: item.file.size, countStyle: .file))
                .zentraFont(10.5).foregroundStyle(Color.zentraTextTertiary)
            SafetyBadge(level: item.safety.level)
        }
        .padding(.vertical, 6)
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

extension ScanCategory {
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

extension ScanSafetyLevel {
    var titleKey: LocalizedStringKey {
        switch self {
        case .safe: "scan.safety.safe"
        case .review: "scan.safety.review"
        case .protected: "scan.safety.protected"
        }
    }
}
