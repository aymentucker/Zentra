import SwiftUI

struct SmartCareView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.zentraBackground, Color.zentraBackground, Color.zentraAccent.opacity(0.07)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 26) {
                Spacer()
                ZentraMark().frame(width: 104, height: 104).shadow(color: Color.zentraAccent.opacity(0.24), radius: 26, x: 0, y: 10)
                VStack(spacing: 9) {
                    Text("smart.title").zentraFont(34, weight: .bold).foregroundStyle(Color.zentraTextPrimary)
                    Text("smart.subtitle").zentraFont(15).foregroundStyle(Color.zentraTextSecondary).multilineTextAlignment(.center)
                }
                ZentraPrimaryButton("smart.scan") {}
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
        ZentraCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).zentraFont(13, weight: .medium).foregroundStyle(Color.zentraTextSecondary)
                Text("status.ready").zentraFont(17, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
