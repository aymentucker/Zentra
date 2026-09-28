import SwiftUI

struct SettingsView: View {
    @AppStorage(AppPreferenceKey.language) private var languageCode = AppPreferences.defaultLanguage
    @AppStorage(AppPreferenceKey.reduceMotion) private var reduceMotion = AppPreferences.defaultReduceMotion
    @AppStorage(AppPreferenceKey.showMenuBarStatus) private var showMenuBarStatus = AppPreferences.defaultShowMenuBarStatus

    var body: some View {
        ZStack {
            Color.zentraBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("settings.title").zentraFont(32, weight: .bold).foregroundStyle(Color.zentraTextPrimary)

                    ZentraSection("settings.language", subtitle: "settings.language.description") {
                        HStack(spacing: 10) {
                            ForEach(AppLanguage.allCases) { language in
                                LanguageOption(language: language, isSelected: languageCode == language.rawValue) {
                                    withAnimation(.easeInOut(duration: 0.18)) { languageCode = language.rawValue }
                                }
                            }
                        }
                    }

                    ZentraSection("settings.experience", subtitle: "settings.experience.description") {
                        VStack(spacing: 0) {
                            ZentraToggle(title: "settings.reduceMotion", subtitle: "settings.reduceMotion.description", isOn: $reduceMotion)
                                .padding(.vertical, 4)
                            Divider().overlay(Color.white.opacity(0.06)).padding(.vertical, 10)
                            ZentraToggle(title: "settings.menuBar", subtitle: "settings.menuBar.description", isOn: $showMenuBarStatus)
                                .padding(.vertical, 4)
                        }
                    }

                    Spacer(minLength: 20)
                }
                .frame(maxWidth: 660, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(38)
            }
        }
    }
}

private struct LanguageOption: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? Color.zentraAccent.opacity(0.16) : Color.white.opacity(0.045))
                        .frame(width: 34, height: 34)
                    Text(language.badge).zentraFont(11, weight: .bold)
                        .foregroundStyle(isSelected ? Color.zentraAccent : Color.zentraTextSecondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.titleKey).zentraFont(13.5, weight: .semibold).foregroundStyle(Color.zentraTextPrimary)
                    Text(language.nativeTitle).zentraFont(11.5).foregroundStyle(Color.zentraTextTertiary)
                }
                Spacer(minLength: 12)
                ZStack {
                    Circle().stroke(isSelected ? Color.zentraAccent : Color.white.opacity(0.18), lineWidth: 1.5).frame(width: 17, height: 17)
                    if isSelected { Circle().fill(Color.zentraAccent).frame(width: 9, height: 9) }
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 58)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(isSelected ? Color.zentraAccent.opacity(0.08) : Color.white.opacity(hovering ? 0.055 : 0.025)))
            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(isSelected ? Color.zentraAccent.opacity(0.55) : Color.white.opacity(0.055), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
