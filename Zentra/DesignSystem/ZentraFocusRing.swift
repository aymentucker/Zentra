import SwiftUI

struct ZentraFocusRing: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    let focused: Bool

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(focused ? Color.zentraAccent.opacity(0.72) : .clear, lineWidth: 2)
                .padding(-2)
        )
        .animation(systemReduceMotion ? nil : .easeOut(duration: 0.14), value: focused)
    }
}

extension View {
    func zentraFocusRing(_ focused: Bool) -> some View {
        modifier(ZentraFocusRing(focused: focused))
    }
}
