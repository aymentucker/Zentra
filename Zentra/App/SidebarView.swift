import SwiftUI

struct SidebarView: View {
    var body: some View {
        ZStack {
            Color.zentraSidebar
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    ZentraMark()
                        .frame(width: 30, height: 30)

                    Text("Zentra")
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.zentraTextPrimary)
                }
                .padding(.top, 10)

                VStack(spacing: 8) {
                    SidebarItem(title: "Smart Care", icon: "sparkles", isSelected: true)
                    SidebarItem(title: "Cleanup", icon: "trash")
                    SidebarItem(title: "Storage", icon: "externaldrive")
                    SidebarItem(title: "Duplicates", icon: "doc.on.doc")
                    SidebarItem(title: "Tidy Up", icon: "square.grid.2x2")
                    SidebarItem(title: "Applications", icon: "app")
                    SidebarItem(title: "Performance", icon: "bolt")
                    SidebarItem(title: "Developer", icon: "chevron.left.forwardslash.chevron.right")
                }

                Spacer()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Macintosh HD")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.zentraTextSecondary)

                    ProgressView(value: 0.64)
                        .tint(Color.zentraAccent)

                    Text("327 GB of 512 GB used")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.zentraTextTertiary)

                    SidebarItem(title: "Settings", icon: "gearshape")
                }
            }
            .padding(18)
        }
    }
}

private struct SidebarItem: View {
    let title: String
    let icon: String
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 18)
                .foregroundStyle(isSelected ? Color.zentraAccent : Color.zentraTextSecondary)

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? Color.zentraTextPrimary : Color.zentraTextSecondary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(isSelected ? Color.zentraSurfaceSelected : .clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(isSelected ? Color.white.opacity(0.06) : .clear, lineWidth: 1)
        )
    }
}
