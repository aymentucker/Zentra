import Foundation

enum AppPreferenceKey {
    static let language = "zentra.language"
    static let reduceMotion = "zentra.accessibility.reduceMotion"
    static let showMenuBarStatus = "zentra.menuBar.showStatus"
}

enum AppPreferences {
    static let defaultLanguage = AppLanguage.english.rawValue
    static let defaultReduceMotion = false
    static let defaultShowMenuBarStatus = true
}
