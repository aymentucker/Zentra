import SwiftUI

struct ZentraMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.zentraAccent.opacity(0.98),
                            Color(red: 0.91, green: 0.35, blue: 0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Path { path in
                path.move(to: CGPoint(x: 0.24, y: 0.30))
                path.addLine(to: CGPoint(x: 0.75, y: 0.30))
                path.addLine(to: CGPoint(x: 0.30, y: 0.70))
                path.addLine(to: CGPoint(x: 0.76, y: 0.70))
            }
            .stroke(
                Color.white.opacity(0.92),
                style: StrokeStyle(lineWidth: 0.10, lineCap: .round, lineJoin: .round)
            )
            .scaleEffect(x: 100, y: 100, anchor: .topLeading)
            .frame(width: 1, height: 1)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
