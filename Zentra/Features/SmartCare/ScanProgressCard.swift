import SwiftUI

struct ScanProgressCard: View {
    let progress: ScanProgress
    @State private var rotating = false
    @AppStorage(AppPreferenceKey.reduceMotion) private var reduceMotion = AppPreferences.defaultReduceMotion

    var body: some View {
        ZentraCard {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.07), lineWidth: 7)
                    Circle()
                        .trim(from: 0.08, to: 0.72)
                        .stroke(Color.zentraAccent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(rotating ? 360 : 0))
                        .animation(reduceMotion ? nil : .linear(duration: 1.15).repeatForever(autoreverses: false), value: rotating)
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.zentraAccent)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 9) {
                    Text("scan.scanning")
                        .zentraFont(14, weight: .semibold)
                        .foregroundStyle(Color.zentraTextPrimary)

                    HStack(spacing: 18) {
                        metric(value: "\(progress.discoveredItems)", label: "scan.items")
                        metric(value: ByteCountFormatter.string(fromByteCount: progress.discoveredBytes, countStyle: .file), label: "scan.discovered")
                    }

                    if let url = progress.currentURL {
                        Text(url.lastPathComponent)
                            .zentraFont(10.5)
                            .foregroundStyle(Color.zentraTextTertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
        .onAppear { rotating = true }
    }

    private func metric(value: String, label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).zentraFont(13, weight: .semibold).foregroundStyle(Color.zentraAccent)
            Text(label).zentraFont(10).foregroundStyle(Color.zentraTextTertiary)
        }
    }
}
