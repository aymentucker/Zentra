import SwiftUI

struct SmartCareView: View {
    @StateObject private var model = SmartCareCoordinator()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.zentraBackground, Color.zentraBackground, Color.zentraAccent.opacity(0.07)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero
                    if case .scanning(let module) = model.state { scanning(module) }
                    if let summary = model.summary { results(summary) }
                    else if !isScanning { readiness }
                    if case .failed = model.state { errorCard }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 48).padding(.vertical, 36)
            }
        }
    }

    private var isScanning: Bool { if case .scanning = model.state { return true }; return false }

    private var hero: some View {
        HStack(spacing: 22) {
            ZentraMark().frame(width: 78, height: 78).shadow(color: Color.zentraAccent.opacity(0.2), radius: 22, y: 8)
            VStack(alignment: .leading, spacing: 7) {
                Text("smart.title").zentraFont(30, weight: .bold).foregroundStyle(Color.zentraTextPrimary)
                Text("smart.subtitle.integrated").zentraFont(12.5).foregroundStyle(Color.zentraTextSecondary)
            }
            Spacer()
            if isScanning { Button("scan.cancel") { model.cancel() }.buttonStyle(.plain).foregroundStyle(Color.zentraTextSecondary) }
            else { ZentraPrimaryButton(model.summary == nil ? "smart.scan" : "smart.scan.again") { model.start() } }
        }
    }

    private func scanning(_ module: SmartCareModule) -> some View {
        ZentraCard { VStack(alignment: .leading, spacing: 14) {
            HStack { ProgressView().controlSize(.small); Text(module.titleKey).zentraFont(13, weight: .semibold); Spacer(); Text("\(Int(model.progress * 100))%").zentraFont(10, weight: .semibold).foregroundStyle(Color.zentraAccent) }
            ProgressView(value: model.progress).tint(Color.zentraAccent)
            if module == .cleanup, let url = model.scanProgress.currentURL { Text(url.path).lineLimit(1).truncationMode(.middle).zentraFont(9).foregroundStyle(Color.zentraTextTertiary) }
            Text("smart.scan.safety").zentraFont(9.5).foregroundStyle(Color.zentraTextTertiary)
        } }
    }

    private func results(_ s: SmartCareSummary) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                statusCard(s)
                safetyMetric("smart.safe", s.safeCount, s.safeBytes, "checkmark.shield.fill", Color.zentraAccent)
                safetyMetric("smart.review", s.reviewCount, s.reviewBytes, "eye.fill", Color.zentraTextSecondary)
                safetyMetric("smart.protected", s.protectedCount, s.protectedBytes, "lock.fill", Color.zentraTextTertiary)
            }
            Text("smart.overview").zentraFont(15, weight: .semibold)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                moduleCard("nav.cleanup", "smart.cleanup.detail", ByteCountFormatter.string(fromByteCount: s.cleanup.totalBytes, countStyle: .file), "sparkles")
                moduleCard("nav.storage", "smart.storage.detail", ByteCountFormatter.string(fromByteCount: s.storage.availableBytes, countStyle: .file), "internaldrive")
                moduleCard("nav.developer", "smart.workspace.detail", ByteCountFormatter.string(fromByteCount: s.workspace.safeBytes + s.workspace.reviewBytes + s.workspace.protectedBytes, countStyle: .file), "hammer")
                moduleCard("nav.applications", "smart.applications.detail", "\(s.applications.applications.count)", "square.grid.2x2")
                moduleCard("nav.performance", "smart.performance.detail", String(format: "CPU %.0f%% · RAM %.0f%%", s.performance.cpuPercent, s.performance.memory.pressure * 100), "gauge.with.dots.needle.67percent")
            }
            recommendation(s)
        }
    }

    private func statusCard(_ s: SmartCareSummary) -> some View {
        ZentraCard { VStack(alignment: .leading, spacing: 7) {
            Image(systemName: s.status == .ready ? "checkmark.circle.fill" : (s.status == .attention ? "exclamationmark.triangle.fill" : "eye.circle.fill")).foregroundStyle(Color.zentraAccent)
            Text(s.status.titleKey).zentraFont(13, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
            Text("smart.status").zentraFont(9.5).foregroundStyle(Color.zentraTextTertiary)
        }.frame(maxWidth: .infinity, alignment: .leading) }
    }

    private func safetyMetric(_ title: LocalizedStringKey, _ count: Int, _ bytes: Int64, _ icon: String, _ color: Color) -> some View {
        ZentraCard { VStack(alignment: .leading, spacing: 6) { Image(systemName: icon).foregroundStyle(color); Text("\(count)").zentraFont(17, weight: .semibold); Text(title).zentraFont(9.5).foregroundStyle(Color.zentraTextSecondary); Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)).zentraFont(8.5).foregroundStyle(Color.zentraTextTertiary) }.frame(maxWidth: .infinity, alignment: .leading) }
    }

    private func moduleCard(_ title: LocalizedStringKey, _ detail: LocalizedStringKey, _ value: String, _ icon: String) -> some View {
        ZentraCard { VStack(alignment: .leading, spacing: 8) { Image(systemName: icon).foregroundStyle(Color.zentraAccent); HStack { Text(title).zentraFont(12, weight: .semibold); Spacer(); Text(value).zentraFont(11, weight: .semibold).foregroundStyle(Color.zentraAccent) }; Text(detail).zentraFont(9.5).foregroundStyle(Color.zentraTextTertiary) }.frame(maxWidth: .infinity, alignment: .leading) }
    }

    private func recommendation(_ s: SmartCareSummary) -> some View {
        ZentraCard { HStack(spacing: 12) { Image(systemName: "lightbulb.fill").foregroundStyle(Color.zentraAccent); VStack(alignment: .leading, spacing: 3) { Text("smart.recommendation").zentraFont(11.5, weight: .semibold); Text(s.reviewCount > 0 ? "smart.recommendation.review" : "smart.recommendation.ready").zentraFont(9.5).foregroundStyle(Color.zentraTextSecondary) }; Spacer(); Text("smart.noAutoDelete").zentraFont(8.5).foregroundStyle(Color.zentraTextTertiary) } }
    }

    private var readiness: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("smart.ready.title").zentraFont(15, weight: .semibold)
            HStack(spacing: 12) { readyCard("nav.cleanup", "sparkles"); readyCard("nav.storage", "internaldrive"); readyCard("nav.developer", "hammer"); readyCard("nav.applications", "square.grid.2x2"); readyCard("nav.performance", "gauge.with.dots.needle.67percent") }
            ZentraCard { HStack { Image(systemName: "doc.on.doc").foregroundStyle(Color.zentraAccent); Text("smart.deepTools").zentraFont(10.5).foregroundStyle(Color.zentraTextSecondary); Spacer() } }
        }
    }

    private func readyCard(_ title: LocalizedStringKey, _ icon: String) -> some View {
        ZentraCard { VStack(alignment: .leading, spacing: 8) { Image(systemName: icon).foregroundStyle(Color.zentraAccent); Text(title).zentraFont(11, weight: .semibold); Text("status.ready").zentraFont(9).foregroundStyle(Color.zentraTextTertiary) }.frame(maxWidth: .infinity, alignment: .leading) }
    }

    private var errorCard: some View { ZentraStateView(state: .error, title: "scan.error.title", message: "scan.error.message", retryAction: { model.start() }) }
}

private extension SmartCareModule {
    var titleKey: LocalizedStringKey {
        switch self { case .cleanup: "smart.scanning.cleanup"; case .storage: "smart.scanning.storage"; case .workspace: "smart.scanning.workspace"; case .applications: "smart.scanning.applications"; case .performance: "smart.scanning.performance" }
    }
}


private extension SmartCareStatus {
    var titleKey: LocalizedStringKey {
        switch self {
        case .ready: "smart.status.ready"
        case .reviewRecommended: "smart.status.review"
        case .attention: "smart.status.attention"
        }
    }
}
