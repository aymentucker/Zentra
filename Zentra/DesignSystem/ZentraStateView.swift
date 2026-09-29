import SwiftUI

enum ZentraViewState {
    case loading
    case empty
    case error
}

struct ZentraStateView: View {
    let state: ZentraViewState
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var retryTitle: LocalizedStringKey = "common.retry"
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            stateIcon
            Text(title).zentraFont(17, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
            Text(message).zentraFont(13).foregroundStyle(Color.zentraTextSecondary).multilineTextAlignment(.center).frame(maxWidth: 380)
            if let retryAction {
                ZentraPrimaryButton(retryTitle, action: retryAction)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private var stateIcon: some View {
        switch state {
        case .loading:
            ProgressView().controlSize(.large).tint(Color.zentraAccent)
        case .empty:
            Image(systemName: "tray").font(.system(size: 28, weight: .light)).foregroundStyle(Color.zentraTextTertiary)
        case .error:
            Image(systemName: "exclamationmark.triangle").font(.system(size: 28, weight: .light)).foregroundStyle(Color.zentraAccent)
        }
    }
}
