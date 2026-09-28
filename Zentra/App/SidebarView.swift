import SwiftUI

struct SidebarView: View {
    @Binding var selection: AppDestination
    @StateObject private var diskVolume = DiskVolumeModel()

    var body: some View {
        ZStack {
            Color.zentraSidebar.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                brand.padding(.bottom, 6)

                section("nav.section.care") {
                    SidebarItem(destination: .smartCare, selection: $selection)
                    SidebarItem(destination: .cleanup, selection: $selection)
                    SidebarItem(destination: .storage, selection: $selection)
                    SidebarItem(destination: .duplicates, selection: $selection)
                    SidebarItem(destination: .tidyUp, selection: $selection)
                }

                section("nav.section.system") {
                    SidebarItem(destination: .applications, selection: $selection)
                    SidebarItem(destination: .performance, selection: $selection)
                    SidebarItem(destination: .developer, selection: $selection)
                }

                Spacer(minLength: 20)
                diskUsage
                SidebarItem(destination: .settings, selection: $selection)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 14)
        }
    }

    private var brand: some View {
        HStack(spacing: 10) {
            ZentraMark().frame(width: 30, height: 30)
            Text("app.name")
                .zentraFont(19, weight: .semibold)
                .foregroundStyle(Color.zentraTextPrimary)
        }
        .padding(.horizontal, 8)
    }

    private var diskUsage: some View {
        Group {
            if let snapshot = diskVolume.snapshot {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(snapshot.name).zentraFont(12, weight: .medium).foregroundStyle(Color.zentraTextSecondary)
                        Spacer()
                        Text(snapshot.usedFraction, format: .percent.precision(.fractionLength(0)))
                            .zentraFont(11, weight: .medium).foregroundStyle(Color.zentraTextTertiary)
                    }
                    ProgressView(value: snapshot.usedFraction).tint(Color.zentraAccent)
                    Text(String(format: NSLocalizedString("disk.usage.format", comment: ""), ByteCountFormatter.string(fromByteCount: snapshot.usedBytes, countStyle: .file), ByteCountFormatter.string(fromByteCount: snapshot.totalBytes, countStyle: .file)))
                        .zentraFont(11).foregroundStyle(Color.zentraTextTertiary)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.025)))
            }
        }
        .task { diskVolume.refresh() }
    }

    private func section<Content: View>(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .zentraFont(10, weight: .semibold)
                .foregroundStyle(Color.zentraTextTertiary)
                .padding(.horizontal, 10)
                .padding(.bottom, 2)
            content()
        }
    }

}

private struct SidebarItem: View {
    let destination: AppDestination
    @Binding var selection: AppDestination
    @State private var hovering = false
    @FocusState private var keyboardFocused: Bool

    private var selected: Bool { selection == destination }

    var body: some View {
        Button { selection = destination } label: {
            HStack(spacing: 11) {
                ZentraIcon(name: destination.iconName)
                    .frame(width: 18, height: 18)
                    .foregroundStyle(selected ? Color.zentraAccent : Color.zentraTextSecondary)
                Text(destination.titleKey)
                    .zentraFont(13.5, weight: .medium)
                    .foregroundStyle(selected ? Color.zentraTextPrimary : Color.zentraTextSecondary)
                Spacer()
            }
            .padding(.horizontal, 11)
            .frame(height: 38)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selected ? Color.zentraSurfaceSelected : (hovering ? Color.white.opacity(0.035) : .clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(selected ? Color.white.opacity(0.055) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .focused($keyboardFocused)
        .zentraFocusRing(keyboardFocused)
        .onHover { hovering = $0 }
        .accessibilityLabel(destination.titleKey)
    }
}
