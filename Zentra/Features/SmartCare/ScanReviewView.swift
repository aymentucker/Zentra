import SwiftUI

struct ScanReviewView: View {
    let snapshot: ScanReviewSnapshot
    @State private var expanded: Set<ScanCategory> = []
    @State private var selected = Set<URL>()
    @State private var plan: CleanupPlan?
    @State private var planError: String?
    @StateObject private var cleanup = CleanupConfirmationModel()
    @Environment(\.layoutDirection) private var layoutDirection

    private var selectedItems: [ClassifiedScanItem] {
        snapshot.groups.values.flatMap { $0 }.filter { selected.contains($0.id) }
    }
    private var selectedBytes: Int64 { selectedItems.reduce(0) { $0 + $1.file.size } }

    var body: some View {
        ZStack {
        VStack(alignment: .leading, spacing: 18) {
            summaryHeader

            LazyVStack(spacing: 10) {
                ForEach(ScanCategory.allCases, id: \.self) { category in
                    if let items = snapshot.groups[category], !items.isEmpty {
                        categoryCard(category, items: items)
                    }
                }
            }

            if !selected.isEmpty { selectionBar }
            if let plan { planPreview(plan) }
            if let planError {
                Text(planError).zentraFont(11).foregroundStyle(Color.zentraTextSecondary)
                    .padding(.horizontal, 4)
            }
            if cleanup.state == .executing { executionProgress }
            if cleanup.state == .completed, let report = cleanup.report { resultView(report) }
        }

        if cleanup.state == .confirming, let plan {
            confirmationOverlay(plan)
        }
        }
    }

    private var summaryHeader: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("scan.review.title").zentraFont(20, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                Text("scan.review.selectHint").zentraFont(12).foregroundStyle(Color.zentraTextSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(ByteCountFormatter.string(fromByteCount: snapshot.totalBytes, countStyle: .file))
                    .zentraFont(19, weight: .semibold).foregroundStyle(Color.zentraAccent)
                Text("scan.review.found").zentraFont(10).foregroundStyle(Color.zentraTextTertiary)
            }
        }
    }

    private func categoryCard(_ category: ScanCategory, items: [ClassifiedScanItem]) -> some View {
        let count = snapshot.counts[category] ?? items.count
        let bytes = snapshot.bytes[category] ?? 0
        let selectable = items.filter { $0.safety.level == .safe }
        let selectedCount = selectable.filter { selected.contains($0.id) }.count

        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    toggleCategory(selectable)
                } label: {
                    selectionIcon(selected: selectedCount, total: selectable.count)
                }
                .buttonStyle(.plain)
                .disabled(selectable.isEmpty)

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
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(14)

            if expanded.contains(category) {
                Divider().overlay(Color.white.opacity(0.06))
                LazyVStack(spacing: 0) {
                    ForEach(items) { item in
                        ScanItemRow(item: item, isSelected: selected.contains(item.id)) {
                            toggle(item)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 6)
            }
        }
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.zentraSurface))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.055), lineWidth: 1))
    }

    private var selectionBar: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.zentraAccent)
            VStack(alignment: .leading, spacing: 2) {
                Text(String(format: NSLocalizedString("scan.selected.count", comment: ""), selected.count))
                    .zentraFont(12, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                Text(ByteCountFormatter.string(fromByteCount: selectedBytes, countStyle: .file))
                    .zentraFont(10.5).foregroundStyle(Color.zentraTextTertiary)
            }
            Spacer()
            Button("scan.plan.create", action: buildPlan)
                .buttonStyle(.plain)
                .zentraFont(11, weight: .semibold)
                .foregroundStyle(Color.zentraAccent)
                .padding(.horizontal, 13).frame(height: 30)
                .background(Capsule().fill(Color.zentraAccent.opacity(0.10)))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.zentraAccent.opacity(0.07)))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.zentraAccent.opacity(0.16), lineWidth: 1))
    }

    private func planPreview(_ plan: CleanupPlan) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "shield.checkered")
                .foregroundStyle(Color.zentraAccent)
            VStack(alignment: .leading, spacing: 3) {
                Text("scan.plan.ready").zentraFont(12, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                Text(String(format: NSLocalizedString("scan.plan.summary", comment: ""), plan.itemCount, ByteCountFormatter.string(fromByteCount: plan.totalBytes, countStyle: .file)))
                    .zentraFont(10.5).foregroundStyle(Color.zentraTextTertiary)
            }
            Spacer()
            Button("cleanup.review.action") { cleanup.requestConfirmation() }
                .buttonStyle(.plain)
                .zentraFont(11, weight: .semibold)
                .foregroundStyle(Color.zentraAccent)
                .padding(.horizontal, 12).frame(height: 30)
                .background(Capsule().fill(Color.zentraAccent.opacity(0.10)))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.zentraSurface))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.zentraAccent.opacity(0.14), lineWidth: 1))
    }

    private func confirmationOverlay(_ plan: CleanupPlan) -> some View {
        ZStack {
            Color.black.opacity(0.50).ignoresSafeArea().onTapGesture { cleanup.dismissConfirmation() }
            ZentraCard {
                VStack(alignment: .leading, spacing: 18) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(Color.zentraAccent)
                    Text("cleanup.confirm.title").zentraFont(19, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                    Text(String(format: NSLocalizedString("cleanup.confirm.message", comment: ""), plan.itemCount, ByteCountFormatter.string(fromByteCount: plan.totalBytes, countStyle: .file)))
                        .zentraFont(12.5).foregroundStyle(Color.zentraTextSecondary).fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Spacer()
                        Button("cleanup.cancel") { cleanup.dismissConfirmation() }
                            .buttonStyle(.plain).zentraFont(12, weight: .medium)
                            .foregroundStyle(Color.zentraTextSecondary).padding(.horizontal, 14).frame(height: 36)
                            .background(Capsule().fill(Color.white.opacity(0.06)))
                        Button("cleanup.confirm.action") { cleanup.execute(plan) }
                            .buttonStyle(.plain).zentraFont(12, weight: .semibold)
                            .foregroundStyle(Color.black).padding(.horizontal, 16).frame(height: 36)
                            .background(Capsule().fill(Color.zentraAccent))
                            .keyboardShortcut(.defaultAction)
                    }
                }.frame(width: 420)
            }.shadow(color: .black.opacity(0.45), radius: 32, y: 14)
        }
    }

    private var executionProgress: some View {
        HStack(spacing: 12) {
            ProgressView().controlSize(.small)
            VStack(alignment: .leading, spacing: 3) {
                Text("cleanup.executing").zentraFont(12, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                Text("cleanup.executing.detail").zentraFont(10.5).foregroundStyle(Color.zentraTextTertiary)
            }
            Spacer()
            Button("cleanup.cancel") { cleanup.cancel() }
                .buttonStyle(.plain).zentraFont(11).foregroundStyle(Color.zentraTextSecondary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.zentraSurface))
    }

    private func resultView(_ report: CleanupExecutionReport) -> some View {
        HStack(spacing: 12) {
            Image(systemName: report.failedCount == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(report.failedCount == 0 ? Color.zentraAccent : Color.zentraTextSecondary)
            VStack(alignment: .leading, spacing: 3) {
                Text(report.failedCount == 0 ? "cleanup.result.success" : "cleanup.result.partial")
                    .zentraFont(12, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                Text(String(format: NSLocalizedString("cleanup.result.summary", comment: ""), report.succeededCount, report.failedCount, ByteCountFormatter.string(fromByteCount: report.processedBytes, countStyle: .file)))
                    .zentraFont(10.5).foregroundStyle(Color.zentraTextTertiary)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.zentraSurface))
    }

    private func buildPlan() {
        do {
            plan = try CleanupPlanBuilder().build(from: selectedItems)
            planError = nil
        } catch {
            plan = nil
            planError = error.localizedDescription
        }
    }

    @ViewBuilder
    private func selectionIcon(selected: Int, total: Int) -> some View {
        if total == 0 {
            Image(systemName: "lock.fill").foregroundStyle(Color.zentraTextTertiary)
        } else if selected == total {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.zentraAccent)
        } else if selected > 0 {
            Image(systemName: "minus.circle.fill").foregroundStyle(Color.zentraAccent)
        } else {
            Image(systemName: "circle").foregroundStyle(Color.zentraTextTertiary)
        }
    }

    private func toggleCategory(_ items: [ClassifiedScanItem]) {
        let ids = Set(items.map(\.id))
        plan = nil
        planError = nil
        if ids.isSubset(of: selected) { selected.subtract(ids) } else { selected.formUnion(ids) }
    }

    private func toggle(_ item: ClassifiedScanItem) {
        guard item.safety.level == .safe else { return }
        plan = nil
        planError = nil
        if selected.contains(item.id) { selected.remove(item.id) } else { selected.insert(item.id) }
    }

    private func chevronName(for category: ScanCategory) -> String {
        if expanded.contains(category) { return "chevron.down" }
        return layoutDirection == .rightToLeft ? "chevron.left" : "chevron.right"
    }
}

private struct ScanItemRow: View {
    let item: ClassifiedScanItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: action) {
                Image(systemName: item.safety.level == .protected ? "lock.fill" : (isSelected ? "checkmark.circle.fill" : "circle"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? Color.zentraAccent : Color.zentraTextTertiary)
                    .frame(width: 18)
            }
            .buttonStyle(.plain)
            .disabled(item.safety.level != .safe)

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
        .padding(.vertical, 7)
    }
}

private struct SafetyBadge: View {
    let level: ScanSafetyLevel
    var body: some View {
        Text(level.titleKey).zentraFont(10, weight: .semibold)
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
        case .creator: "scan.category.creator"
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
