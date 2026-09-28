import SwiftUI

/// Root application shell.
///
/// Important: the physical window shell always uses LTR coordinates so SwiftUI
/// cannot mirror the sidebar placement behind our back. Locale direction is
/// applied only inside the sidebar and content regions.
struct ContentView: View {
    @State private var selection: AppDestination = .smartCare
    @AppStorage(AppPreferenceKey.language) private var languageCode = AppPreferences.defaultLanguage

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
        // Keep physical window placement deterministic.
        .environment(\.layoutDirection, .leftToRight)
        .background(Color.zentraBackground)
        .preferredColorScheme(.dark)
        .id("shell-\(language.rawValue)")
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
        case .smartCare:
            SmartCareView()
        case .settings:
            SettingsView()
        default:
            FeaturePlaceholderView(destination: selection)
        }
    }
}

enum AppShellMetrics {
    static let sidebarWidth: CGFloat = 246
}

#Preview("English") {
    ContentView()
        .frame(width: 1180, height: 760)
}
