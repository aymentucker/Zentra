import SwiftUI

struct ZentraToggle: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey?
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.16)) { isOn.toggle() }
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).zentraFont(13.5, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                    if let subtitle {
                        Text(subtitle).zentraFont(11.5).foregroundStyle(Color.zentraTextTertiary)
                    }
                }
                Spacer()
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule().fill(isOn ? Color.zentraAccent : Color.white.opacity(0.10)).frame(width: 38, height: 22)
                    Circle().fill(isOn ? Color.black.opacity(0.82) : Color.zentraTextSecondary).frame(width: 16, height: 16).padding(3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}
