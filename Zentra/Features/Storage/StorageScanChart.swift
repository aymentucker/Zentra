import SwiftUI

struct StorageScanChart: View {
    let files: Int
    let bytes: Int64
    let currentURL: URL?

    @State private var phase: CGFloat = 0

    private var bars: [CGFloat] {
        [0.28, 0.46, 0.34, 0.68, 0.52, 0.82, 0.58, 0.92, 0.64, 0.76, 0.48, 0.7]
    }

    var body: some View {
        ZentraCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.zentraAccent)
                                .frame(width: 7, height: 7)
                                .shadow(color: Color.zentraAccent.opacity(0.7), radius: 6)
                            Text("storage.scanChart.title")
                                .zentraFont(13, weight: .semibold)
                                .foregroundStyle(Color.zentraTextPrimary)
                        }
                        Text("storage.scanChart.subtitle")
                            .zentraFont(9.5)
                            .foregroundStyle(Color.zentraTextTertiary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
                            .zentraFont(20, weight: .semibold)
                            .foregroundStyle(Color.zentraTextPrimary)
                        Text(String(format: NSLocalizedString("storage.scanChart.files", comment: ""), files))
                            .zentraFont(9.5)
                            .foregroundStyle(Color.zentraTextTertiary)
                    }
                }

                GeometryReader { proxy in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    ZStack(alignment: .bottomLeading) {
                        ForEach(0..<4, id: \.self) { index in
                            Rectangle()
                                .fill(Color.white.opacity(0.035))
                                .frame(height: 1)
                                .offset(y: -CGFloat(index) * height / 3)
                        }

                        HStack(alignment: .bottom, spacing: 7) {
                            ForEach(Array(bars.enumerated()), id: \.offset) { index, value in
                                let pulse = 0.82 + 0.18 * sin(phase + CGFloat(index) * 0.62)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.zentraAccent.opacity(0.22), Color.zentraAccent.opacity(0.9)],
                                            startPoint: .bottom,
                                            endPoint: .top
                                        )
                                    )
                                    .frame(
                                        maxWidth: .infinity,
                                        maxHeight: max(8, height * value * pulse)
                                    )
                            }
                        }
                        .frame(width: width, height: height, alignment: .bottom)

                        LinearGradient(
                            colors: [.clear, Color.zentraAccent.opacity(0.12), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: max(70, width * 0.2))
                        .offset(x: phase.truncatingRemainder(dividingBy: width + 100) - 80)
                        .blendMode(.screen)
                    }
                    .clipped()
                }
                .frame(height: 105)

                HStack(spacing: 9) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.zentraAccent)
                    Text(currentURL?.path ?? String(localized: "storage.scanChart.preparing"))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .zentraFont(9.5)
                        .foregroundStyle(Color.zentraTextTertiary)
                    Spacer()
                    ProgressView().controlSize(.small)
                }
            }
            .padding(2)
        }
        .task {
            phase = 0
            withAnimation(.linear(duration: 3.2).repeatForever(autoreverses: false)) {
                phase = 1600
            }
        }
    }
}
