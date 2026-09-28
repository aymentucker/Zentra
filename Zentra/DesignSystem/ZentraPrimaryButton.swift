import SwiftUI

struct ZentraPrimaryButton: View {
    let title: LocalizedStringKey
    let action: () -> Void
    @State private var hovering = false

    init(_ title: LocalizedStringKey, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .zentraFont(15, weight: .semibold)
                .foregroundStyle(.black)
                .padding(.horizontal, 30)
                .frame(height: 44)
                .background(Capsule().fill(Color.zentraAccent.opacity(hovering ? 0.92 : 1)))
                .scaleEffect(hovering ? 1.015 : 1)
                .shadow(color: Color.zentraAccent.opacity(hovering ? 0.38 : 0.28), radius: 14, x: 0, y: 7)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.14), value: hovering)
    }
}
