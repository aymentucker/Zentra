import SwiftUI

struct ContentView: View {
    @State private var selection: AppDestination = .smartCare
    @AppStorage("zentra.language") private var languageCode = AppLanguage.english.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                detail
                    .frame(
                        width: max(0, proxy.size.width - AppShellMetrics.sidebarWidth),
                        height: proxy.size.height
                    )
                    .offset(x: language == .arabic ? 0 : AppShellMetrics.sidebarWidth)

                sidebar
                    .frame(width: AppShellMetrics.sidebarWidth, height: proxy.size.height)
                    .offset(x: language == .arabic ? proxy.size.width - AppShellMetrics.sidebarWidth : 0)
            }
            .clipped()
        }
        .background(Color.zentraBackground)
        .environment(\.locale, Locale(identifier: language.localeIdentifier))
        .environment(\.layoutDirection, language.layoutDirection)
        .preferredColorScheme(.dark)
        .id(language.rawValue)
    }

    private var sidebar: some View {
        SidebarView(selection: $selection)
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

enum AppShellMetrics {
    static let sidebarWidth: CGFloat = 246
}

#Preview {
    ContentView()
        .frame(width: 1180, height: 760)
}
