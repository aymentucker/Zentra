import SwiftUI

/// Temporary native mark used during M0.
/// Drawn in the view's local coordinate space so it scales correctly at every size.
struct ZentraMark: View {
    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let strokeWidth = max(2, size * 0.085)

            ZStack {
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.zentraAccent,
                                Color(red: 0.91, green: 0.35, blue: 0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Path { path in
                    path.move(to: CGPoint(x: size * 0.29, y: size * 0.32))
                    path.addLine(to: CGPoint(x: size * 0.71, y: size * 0.32))
                    path.addLine(to: CGPoint(x: size * 0.31, y: size * 0.68))
                    path.addLine(to: CGPoint(x: size * 0.71, y: size * 0.68))
                }
                .stroke(
                    Color.white.opacity(0.94),
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
            }
            .frame(width: size, height: size)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
