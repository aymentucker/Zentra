import SwiftUI

struct ZentraSection<Content: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    @ViewBuilder let content: Content

    init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ZentraCard {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 9) {
                    Text(title)
                        .zentraFont(17, weight: .semibold)
                        .foregroundStyle(Color.zentraTextPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .zentraFont(13)
                            .foregroundStyle(Color.zentraTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
