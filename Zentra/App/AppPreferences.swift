import Foundation

enum AppPreferenceKey {
    static let language = "zentra.language"
}

/// Central namespace for preferences shared by the application shell.
/// Feature-specific preferences should live with their feature.
enum AppPreferences {
    static let defaultLanguage = AppLanguage.english.rawValue
}
