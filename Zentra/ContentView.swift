import SwiftUI

struct ContentView: View {
    @State private var selection: AppDestination = .smartCare
    @AppStorage("zentra.language") private var languageCode = AppLanguage.english.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    var body: some View {
        HStack(spacing: 0) {
            if language == .arabic {
                detail
                sidebar
            } else {
                sidebar
                detail
            }
        }
        .background(Color.zentraBackground)
        .environment(\.locale, Locale(identifier: language.localeIdentifier))
        .environment(\.layoutDirection, language.layoutDirection)
        .preferredColorScheme(.dark)
    }

    private var sidebar: some View {
        SidebarView(selection: $selection)
            .frame(width: 246)
    }

    private var detail: some View {
        destinationView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
