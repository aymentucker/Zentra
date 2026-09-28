import SwiftUI

enum ZentraFontWeight {
    case regular, medium, semibold, bold

    var cairoFontName: String {
        // Cairo is bundled as a variable font. On macOS SwiftUI does not expose
        // Font.variation, and applying .weight() to this custom font produces
        // CoreText descriptor warnings. Use the registered Cairo face directly.
        "Cairo"
    }

    var interFontName: String {
        "Inter"
    }
}

private struct ZentraTypographyModifier: ViewModifier {
    @Environment(\.locale) private var locale
    let size: CGFloat
    let weight: ZentraFontWeight

    private var isArabic: Bool { locale.language.languageCode?.identifier == "ar" }
    private var family: String { isArabic ? weight.cairoFontName : weight.interFontName }

    func body(content: Content) -> some View {
        content
            .font(.custom(family, size: size))
            .lineSpacing(isArabic ? max(2, size * 0.16) : max(1, size * 0.06))
    }
}

extension View {
    func zentraFont(_ size: CGFloat, weight: ZentraFontWeight = .regular) -> some View {
        modifier(ZentraTypographyModifier(size: size, weight: weight))
    }
}
