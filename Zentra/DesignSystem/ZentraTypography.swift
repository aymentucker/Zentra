import SwiftUI

enum ZentraFontWeight {
    case regular, medium, semibold, bold

    var swiftUIWeight: Font.Weight {
        switch self {
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        }
    }
}

private struct ZentraTypographyModifier: ViewModifier {
    @Environment(\.locale) private var locale
    let size: CGFloat
    let weight: ZentraFontWeight

    private var isArabic: Bool { locale.language.languageCode?.identifier == "ar" }
    private var family: String { isArabic ? "Cairo" : "Inter" }

    func body(content: Content) -> some View {
        content
            .font(.custom(family, size: size).weight(weight.swiftUIWeight))
            .lineSpacing(isArabic ? max(2, size * 0.16) : max(1, size * 0.06))
    }
}

extension View {
    func zentraFont(_ size: CGFloat, weight: ZentraFontWeight = .regular) -> some View {
        modifier(ZentraTypographyModifier(size: size, weight: weight))
    }
}
