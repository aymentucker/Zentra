import SwiftUI

struct ContentView: View {
    @State private var selection: AppDestination = .smartCare
    @AppStorage("zentra.language") private var languageCode = AppLanguage.english.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 228, ideal: 246, max: 278)
        } detail: {
            destinationView
        }
        .navigationSplitViewStyle(.balanced)
        .environment(\.locale, Locale(identifier: language.localeIdentifier))
        .environment(\.layoutDirection, language.layoutDirection)
        .preferredColorScheme(.dark)
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

#Preview {
    ContentView()
        .frame(width: 1180, height: 760)
}
