import SwiftUI

struct CleanupView: View {
    @StateObject private var scanSession = ScanSession()
    private let targetPolicy = ScanTargetPolicy()

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
            cleanupCard("cleanup.userCaches", detail: "cleanup.userCaches.detail", icon: "shippingbox")
            cleanupCard("cleanup.logs", detail: "cleanup.logs.detail", icon: "doc.text")
            cleanupCard("cleanup.safePolicy", detail: "cleanup.safePolicy.detail", icon: "shield.checkered")
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
        scanSession.start(targets: targetPolicy.smartCareTargets())
    }
}
