import SwiftUI

struct ZentraToast: View {
    let message: LocalizedStringKey
    var systemImage: String = "checkmark.circle.fill"

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage).foregroundStyle(Color.zentraAccent)
            Text(message).zentraFont(12.5, weight: .medium).foregroundStyle(Color.zentraTextPrimary)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 38)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
        .shadow(color: .black.opacity(0.24), radius: 16, y: 8)
    }
}
