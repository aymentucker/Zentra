import Foundation

/// Localization used by model/service code and formatted values.
///
/// SwiftUI's environment locale is scoped to views. Foundation APIs such as
/// NSLocalizedString and ByteCountFormatter otherwise follow the process/system
/// locale, which can disagree with Zentra's in-app language preference.
enum ZentraLocalization {
    static var languageCode: String {
        UserDefaults.standard.string(forKey: "zentra.language") ?? "en"
    }

    static var locale: Locale {
        Locale(identifier: languageCode == "ar" ? "ar" : "en")
    }

    static var bundle: Bundle {
        let code = languageCode == "ar" ? "ar" : "en"
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let localized = Bundle(path: path) else { return .main }
        return localized
    }

    static func string(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: locale, arguments: arguments)
    }

    static func bytes(_ value: Int64, style: ByteCountFormatter.CountStyle = .file) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = style
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.isAdaptive = true
        formatter.includesUnit = true
        formatter.locale = locale
        return formatter.string(fromByteCount: value)
    }

    static func localizedNumber(_ value: Double, maximumFractionDigits: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
