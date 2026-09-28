import SwiftUI

struct SmartCareView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.zentraBackground,
                    Color.zentraBackground,
                    Color.zentraAccent.opacity(0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 26) {
                Spacer()

                ZentraMark()
                    .frame(width: 104, height: 104)
                    .shadow(color: Color.zentraAccent.opacity(0.24), radius: 26, x: 0, y: 10)

                VStack(spacing: 9) {
                    Text("smart.title")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.zentraTextPrimary)

                    Text("smart.subtitle")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.zentraTextSecondary)
                        .multilineTextAlignment(.center)
                }

                Button(action: {}) {
                    Text("smart.scan")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 30)
                        .frame(height: 44)
                        .background(Capsule().fill(Color.zentraAccent))
                        .shadow(color: Color.zentraAccent.opacity(0.30), radius: 14, x: 0, y: 7)
                }
                .buttonStyle(.plain)

                HStack(spacing: 14) {
                    StatusCard(title: "nav.cleanup")
                    StatusCard(title: "nav.performance")
                    StatusCard(title: "nav.applications")
                }
                .frame(maxWidth: 720)

                Spacer()
            }
            .padding(36)
        }
    }
}

private struct StatusCard: View {
    let title: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.zentraTextSecondary)

            Text("status.ready")
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
