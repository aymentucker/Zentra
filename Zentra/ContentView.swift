import SwiftUI

/// Root application shell. Physical placement stays LTR; localized regions
/// receive their own locale and layout direction.
struct ContentView: View {
    @State private var selection: AppDestination = .smartCare
    @AppStorage(AppPreferenceKey.language) private var languageCode = AppPreferences.defaultLanguage
    @AppStorage(AppPreferenceKey.reduceMotion) private var reduceMotion = AppPreferences.defaultReduceMotion

    private var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    var body: some View {
        HStack(spacing: 0) {
            if language == .arabic {
                contentRegion
                sidebarRegion
            } else {
                sidebarRegion
                contentRegion
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .background(Color.zentraBackground)
        .preferredColorScheme(.dark)
        .id("shell-\(language.rawValue)")
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: selection)
    }

    private var sidebarRegion: some View {
        SidebarView(selection: $selection)
            .frame(width: AppShellMetrics.sidebarWidth)
            .frame(maxHeight: .infinity)
            .environment(\.locale, Locale(identifier: language.localeIdentifier))
            .environment(\.layoutDirection, language.layoutDirection)
    }

    private var contentRegion: some View {
        destinationView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(\.locale, Locale(identifier: language.localeIdentifier))
            .environment(\.layoutDirection, language.layoutDirection)
    }

    @ViewBuilder
    private var destinationView: some View {
        switch selection {
        case .smartCare: SmartCareView()
        case .cleanup: CleanupView()
        case .storage: StorageView()
        case .duplicates: DuplicatesView()
        case .tidyUp: TidyUpView()
        case .developer: DeveloperCleanerView()
        case .settings: SettingsView()
        default: FeaturePlaceholderView(destination: selection)
        }
    }
}

enum AppShellMetrics {
    static let sidebarWidth: CGFloat = 246
}

#Preview("English") {
    ContentView().frame(width: 1180, height: 760)
}
