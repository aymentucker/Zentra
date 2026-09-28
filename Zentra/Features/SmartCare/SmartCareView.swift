import SwiftUI

struct SmartCareView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.zentraBackground,
                    Color.zentraBackground,
                    Color.zentraAccent.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZentraMark()
                    .frame(width: 110, height: 110)
                    .shadow(color: Color.zentraAccent.opacity(0.28), radius: 28, x: 0, y: 12)

                VStack(spacing: 10) {
                    Text("Smart Care")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.zentraTextPrimary)

                    Text("Clean, optimize and review your Mac in a single scan.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.zentraTextSecondary)
                }

                Button(action: {}) {
                    Text("Scan")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 30)
                        .frame(height: 44)
                        .background(
                            Capsule()
                                .fill(Color.zentraAccent)
                        )
                        .shadow(color: Color.zentraAccent.opacity(0.35), radius: 16, x: 0, y: 8)
                }
                .buttonStyle(.plain)

                HStack(spacing: 14) {
                    StatusCard(title: "Cleanup", value: "Ready")
                    StatusCard(title: "Performance", value: "Ready")
                    StatusCard(title: "Apps", value: "Ready")
                }
                .frame(maxWidth: 720)

                Spacer()
            }
            .padding(36)
        }
    }
}

private struct StatusCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.zentraTextSecondary)

            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.zentraTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.zentraSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
