import SwiftUI

struct SmartCareView: View {
    @StateObject private var scanSession = ScanSession()
    private let targetPolicy = ScanTargetPolicy()

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.zentraBackground, Color.zentraBackground, Color.zentraAccent.opacity(0.07)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 26) {
                    ZentraMark().frame(width: 92, height: 92).shadow(color: Color.zentraAccent.opacity(0.24), radius: 26, x: 0, y: 10)

                    VStack(spacing: 9) {
                        Text("smart.title").zentraFont(34, weight: .bold).foregroundStyle(Color.zentraTextPrimary)
                        Text("smart.subtitle").zentraFont(15).foregroundStyle(Color.zentraTextSecondary).multilineTextAlignment(.center)
                    }

                    scanAction

                    if scanSession.state == .scanning || scanSession.state == .preparingResults {
                        ScanProgressCard(progress: scanSession.progress)
                    }

                    if let review = scanSession.review {
                        ScanReviewView(snapshot: review)
                    }

                    if case .failed = scanSession.state {
                        ZentraStateView(
                            state: .error,
                            title: "scan.error.title",
                            message: "scan.error.message",
                            retryAction: startScan
                        )
                    }

                    if scanSession.result == nil && scanSession.state != .scanning && scanSession.state != .preparingResults {
                        HStack(spacing: 14) {
                            StatusCard(title: "nav.cleanup")
                            StatusCard(title: "nav.performance")
                            StatusCard(title: "nav.applications")
                        }
                        .frame(maxWidth: 720)
                    }
                }
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
                .padding(36)
            }
        }
    }

    @ViewBuilder
    private var scanAction: some View {
        if scanSession.state == .scanning {
            Button("scan.cancel") { scanSession.cancel() }
                .buttonStyle(.plain)
                .zentraFont(13, weight: .medium)
                .foregroundStyle(Color.zentraTextSecondary)
        } else {
            ZentraPrimaryButton("smart.scan", action: startScan)
        }
    }

    private func startScan() {
        scanSession.start(targets: targetPolicy.smartCareTargets())
    }
}

private struct StatusCard: View {
    let title: LocalizedStringKey
    var body: some View {
        ZentraCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).zentraFont(13, weight: .medium).foregroundStyle(Color.zentraTextSecondary)
                Text("status.ready").zentraFont(17, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
