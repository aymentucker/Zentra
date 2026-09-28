import SwiftUI

enum ZentraFontWeight {
    case regular, medium, semibold, bold

    var variableAxisValue: Double {
        switch self {
        case .regular: 400
        case .medium: 500
        case .semibold: 600
        case .bold: 700
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
            // The bundled fonts are variable fonts. Configure their native wght
            // axis instead of asking SwiftUI to synthesize a Font.Weight.
            .font(.custom(family, size: size).variation("wght", weight.variableAxisValue))
            .lineSpacing(isArabic ? max(2, size * 0.16) : max(1, size * 0.06))
    }
}

extension View {
    func zentraFont(_ size: CGFloat, weight: ZentraFontWeight = .regular) -> some View {
        modifier(ZentraTypographyModifier(size: size, weight: weight))
    }
}
