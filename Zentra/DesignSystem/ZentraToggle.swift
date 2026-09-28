import SwiftUI

struct ZentraToggle: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey?
    @Binding var isOn: Bool
    @FocusState private var focused: Bool

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.16)) { isOn.toggle() }
        } label: {
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(title)
                        .zentraFont(13.5, weight: .semibold)
                        .foregroundStyle(Color.zentraTextPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .zentraFont(11.5)
                            .foregroundStyle(Color.zentraTextTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 20)
                ZStack(alignment: isOn ? .trailing : .leading) {
                    Capsule().fill(isOn ? Color.zentraAccent : Color.white.opacity(0.10)).frame(width: 38, height: 22)
                    Circle().fill(isOn ? Color.black.opacity(0.82) : Color.zentraTextSecondary).frame(width: 16, height: 16).padding(3)
                }
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focused($focused)
        .zentraFocusRing(focused)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}
