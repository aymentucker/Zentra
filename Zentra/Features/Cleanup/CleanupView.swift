import SwiftUI

struct CleanupView: View {
    @StateObject private var scanSession = ScanSession()
    private let sourceCatalog = CleanupSourceCatalog()
    @State private var enabledSources = Set(CleanupSourceKind.allCases)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.zentraBackground, Color.zentraBackground, Color.zentraAccent.opacity(0.055)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    if scanSession.state == .scanning || scanSession.state == .preparingResults {
                        ScanProgressCard(progress: scanSession.progress)
                    }

                    if let review = scanSession.review {
                        ScanReviewView(snapshot: review)
                    } else if scanSession.state != .scanning && scanSession.state != .preparingResults {
                        cleanupCategories
                    }
                }
                .frame(maxWidth: 820)
                .frame(maxWidth: .infinity)
                .padding(36)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 7) {
                Text("cleanup.title").zentraFont(30, weight: .bold).foregroundStyle(Color.zentraTextPrimary)
                Text("cleanup.subtitle").zentraFont(13).foregroundStyle(Color.zentraTextSecondary)
            }
            Spacer()
            if scanSession.state == .scanning {
                Button("scan.cancel") { scanSession.cancel() }
                    .buttonStyle(.plain).zentraFont(12, weight: .medium)
                    .foregroundStyle(Color.zentraTextSecondary)
            } else {
                ZentraPrimaryButton("cleanup.scan", action: startScan)
            }
        }
    }

    private var cleanupCategories: some View {
        VStack(spacing: 12) {
            ForEach(sourceCatalog.availableSources()) { source in
                sourceCard(source)
            }
            cleanupCard("cleanup.safePolicy", detail: "cleanup.safePolicy.detail", icon: "shield.checkered")
        }
    }

    private func sourceCard(_ source: CleanupSource) -> some View {
        let enabled = enabledSources.contains(source.kind)
        return ZentraCard {
            HStack(spacing: 14) {
                Image(systemName: source.kind.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.zentraAccent)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.zentraAccent.opacity(0.10)))
                VStack(alignment: .leading, spacing: 4) {
                    Text(source.kind.titleKey).zentraFont(13, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                    Text(source.kind.detailKey).zentraFont(11).foregroundStyle(Color.zentraTextTertiary)
                    Text(String(format: NSLocalizedString("cleanup.locations.count", comment: ""), source.targets.count))
                        .zentraFont(10).foregroundStyle(Color.zentraTextTertiary)
                }
                Spacer()
                Button {
                    if enabled { enabledSources.remove(source.kind) } else { enabledSources.insert(source.kind) }
                } label: {
                    Image(systemName: enabled ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(enabled ? Color.zentraAccent : Color.zentraTextTertiary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .disabled(source.targets.isEmpty)
            }
            .opacity(source.targets.isEmpty ? 0.45 : 1)
        }
    }

    private func cleanupCard(_ title: LocalizedStringKey, detail: LocalizedStringKey, icon: String) -> some View {
        ZentraCard {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.zentraAccent)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.zentraAccent.opacity(0.10)))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).zentraFont(13, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                    Text(detail).zentraFont(11).foregroundStyle(Color.zentraTextTertiary)
                }
                Spacer()
            }
        }
    }

    private func startScan() {
        let targets = sourceCatalog.availableSources()
            .filter { enabledSources.contains($0.kind) }
            .flatMap(\.targets)
        scanSession.start(targets: targets)
    }
}


extension CleanupSourceKind {
    var titleKey: LocalizedStringKey {
        switch self {
        case .userCaches: "cleanup.userCaches"
        case .applicationLogs: "cleanup.logs"
        case .developer: "cleanup.developer"
        case .creator: "cleanup.creator"
        }
    }

    var detailKey: LocalizedStringKey {
        switch self {
        case .userCaches: "cleanup.userCaches.detail"
        case .applicationLogs: "cleanup.logs.detail"
        case .developer: "cleanup.developer.detail"
        case .creator: "cleanup.creator.detail"
        }
    }

    var icon: String {
        switch self {
        case .userCaches: "shippingbox"
        case .applicationLogs: "doc.text"
        case .developer: "hammer"
        case .creator: "film"
        }
    }
}
