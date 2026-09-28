import SwiftUI

struct SettingsView: View {
    @AppStorage(AppPreferenceKey.language) private var languageCode = AppPreferences.defaultLanguage

    var body: some View {
        ZStack {
            Color.zentraBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("settings.title")
                        .zentraFont(32, weight: .bold)
                        .foregroundStyle(Color.zentraTextPrimary)

                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("settings.language")
                                .zentraFont(17, weight: .semibold)
                                .foregroundStyle(Color.zentraTextPrimary)

                            Text("settings.language.description")
                                .zentraFont(13)
                                .foregroundStyle(Color.zentraTextSecondary)
                        }

                        HStack(spacing: 10) {
                            ForEach(AppLanguage.allCases) { language in
                                LanguageOption(
                                    language: language,
                                    isSelected: languageCode == language.rawValue
                                ) {
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        languageCode = language.rawValue
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: 620, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.zentraSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.055), lineWidth: 1)
                    )

                    Spacer(minLength: 20)
                }
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

                    Text(language.badge)
                        .zentraFont(11, weight: .bold)
                        .foregroundStyle(isSelected ? Color.zentraAccent : Color.zentraTextSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(language.titleKey)
                        .zentraFont(13.5, weight: .semibold)
                        .foregroundStyle(Color.zentraTextPrimary)

                    Text(language.nativeTitle)
                        .zentraFont(11.5)
                        .foregroundStyle(Color.zentraTextTertiary)
                }

                Spacer(minLength: 12)

                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.zentraAccent : Color.white.opacity(0.18), lineWidth: 1.5)
                        .frame(width: 17, height: 17)

                    if isSelected {
                        Circle()
                            .fill(Color.zentraAccent)
                            .frame(width: 9, height: 9)
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 58)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(
                        isSelected
                        ? Color.zentraAccent.opacity(0.08)
                        : Color.white.opacity(hovering ? 0.055 : 0.025)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(
                        isSelected ? Color.zentraAccent.opacity(0.55) : Color.white.opacity(0.055),
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
