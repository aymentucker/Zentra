import SwiftUI

/// Root application shell. Feature views are kept alive for the lifetime of
/// the window so scan results, selections and navigation state survive when
/// the user moves between sidebar destinations.
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
        persistentDestinationStack
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(\.locale, Locale(identifier: language.localeIdentifier))
            .environment(\.layoutDirection, language.layoutDirection)
    }

    /// Do not rebuild a feature every time it is selected. Hiding the inactive
    /// views preserves each feature's @StateObject, scan results and selections.
    private var persistentDestinationStack: some View {
        ZStack {
            persistent(.smartCare) { SmartCareView() }
            persistent(.cleanup) { CleanupView(isActive: selection == .cleanup) }
            persistent(.storage) { StorageView() }
            persistent(.duplicates) { DuplicatesView() }
            persistent(.tidyUp) { TidyUpView() }
            persistent(.applications) { ApplicationsView(isActive: selection == .applications) }
            persistent(.performance) { PerformanceView(isActive: selection == .performance) }
            persistent(.developer) { DeveloperCleanerView(isActive: selection == .developer) }
            persistent(.settings) { SettingsView() }

            if !persistentDestinations.contains(selection) {
                FeaturePlaceholderView(destination: selection)
            }
        }
    }

    private var persistentDestinations: Set<AppDestination> {
        [.smartCare, .cleanup, .storage, .duplicates, .tidyUp, .applications, .performance, .developer, .settings]
    }

    @ViewBuilder
    private func persistent<Content: View>(
        _ destination: AppDestination,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .opacity(selection == destination ? 1 : 0)
            .allowsHitTesting(selection == destination)
            .accessibilityHidden(selection != destination)
            .zIndex(selection == destination ? 1 : 0)
    }
}

enum AppShellMetrics {
    static let sidebarWidth: CGFloat = 246
}

#Preview("English") {
    ContentView().frame(width: 1180, height: 760)
}
