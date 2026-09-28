import SwiftUI

struct SettingsView: View {
    @AppStorage("zentra.language") private var languageCode = AppLanguage.english.rawValue

    var body: some View {
        ZStack {
            Color.zentraBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {
                Text("settings.title")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.zentraTextPrimary)

                VStack(alignment: .leading, spacing: 12) {
                    Text("settings.language")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.zentraTextPrimary)

                    Text("settings.language.description")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.zentraTextSecondary)

                    Picker("settings.language", selection: $languageCode) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.titleKey).tag(language.rawValue)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 220)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.zentraSurface)
                )

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(38)
        }
    }
}
