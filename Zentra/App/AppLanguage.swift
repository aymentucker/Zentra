import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case arabic = "ar"

    var id: String { rawValue }
    var localeIdentifier: String { rawValue }
    var layoutDirection: LayoutDirection { self == .arabic ? .rightToLeft : .leftToRight }

    var titleKey: LocalizedStringKey {
        switch self {
        case .english: "language.english"
        case .arabic: "language.arabic"
        }
    }
}
