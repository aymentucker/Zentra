import SwiftUI

struct ZentraDialog: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let confirmTitle: LocalizedStringKey
    let cancelTitle: LocalizedStringKey
    var isDestructive = false
    let confirm: () -> Void
    let cancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.46).ignoresSafeArea().onTapGesture(perform: cancel)

            ZentraCard {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 9) {
                        Text(title).zentraFont(19, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                        Text(message).zentraFont(13).foregroundStyle(Color.zentraTextSecondary).fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 10) {
                        Spacer()
                        Button(cancelTitle, action: cancel)
                            .buttonStyle(.plain)
                            .zentraFont(13, weight: .medium)
                            .foregroundStyle(Color.zentraTextSecondary)
                            .padding(.horizontal, 16).frame(height: 38)
                            .background(Capsule().fill(Color.white.opacity(0.06)))

                        Button(confirmTitle, action: confirm)
                            .buttonStyle(.plain)
                            .zentraFont(13, weight: .semibold)
                            .foregroundStyle(isDestructive ? Color.white : Color.black)
                            .padding(.horizontal, 18).frame(height: 38)
                            .background(Capsule().fill(isDestructive ? Color.red.opacity(0.78) : Color.zentraAccent))
                            .keyboardShortcut(.defaultAction)
                    }
                }
                .frame(width: 410)
            }
            .shadow(color: .black.opacity(0.45), radius: 34, y: 16)
        }
        .transition(.opacity)
    }
}
