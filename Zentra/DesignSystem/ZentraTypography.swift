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

    private var family: String {
        locale.language.languageCode?.identifier == "ar" ? "Cairo" : "Inter"
    }

    func body(content: Content) -> some View {
        content.font(.custom(family, size: size).weight(weight.swiftUIWeight))
    }
}

extension View {
    func zentraFont(_ size: CGFloat, weight: ZentraFontWeight = .regular) -> some View {
        modifier(ZentraTypographyModifier(size: size, weight: weight))
    }
}
