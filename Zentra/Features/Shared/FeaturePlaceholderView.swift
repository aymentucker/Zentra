import SwiftUI

struct FeaturePlaceholderView: View {
    let destination: AppDestination

    var body: some View {
        ZStack {
            Color.zentraBackground.ignoresSafeArea()

            VStack(spacing: 18) {
                ZentraIcon(name: destination.iconName)
                    .frame(width: 42, height: 42)
                    .foregroundStyle(Color.zentraAccent)

                Text(destination.titleKey)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.zentraTextPrimary)

                Text("feature.coming.title")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.zentraTextSecondary)

                Text("feature.coming.subtitle")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.zentraTextTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 440)
            }
            .padding(40)
        }
    }
}
