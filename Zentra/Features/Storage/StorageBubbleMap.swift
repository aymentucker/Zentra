import SwiftUI

struct StorageBubbleMap: View {
    let nodes: [StorageNode]
    let selected: Set<URL>
    let onSelect: (StorageNode) -> Void
    let onOpenDirectory: (StorageNode) -> Void
    let onReveal: (StorageNode) -> Void
    let onOpen: (StorageNode) -> Void
    let onTrash: (StorageNode) -> Void

    private var visible: [StorageNode] { Array(nodes.prefix(36)) }

    var body: some View {
        GeometryReader { proxy in
            let layout = BubblePackingLayout.pack(nodes: visible, in: proxy.size)
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.zentraSurface.opacity(0.72))
                    .overlay(alignment: .topLeading) {
                        LinearGradient(colors: [Color.zentraAccent.opacity(0.035), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                    }

                if visible.isEmpty {
                    Text("storage.visual.empty").zentraFont(11).foregroundStyle(Color.zentraTextTertiary)
                }

                ForEach(layout) { entry in
                    bubble(entry.node, diameter: entry.diameter)
                        .position(entry.center)
                }
            }
            .clipped()
        }
        .frame(minHeight: 520)
    }

    private func bubble(_ node: StorageNode, diameter: CGFloat) -> some View {
        let active = selected.contains(node.id)
        return Button {
            if node.isDirectory { onOpenDirectory(node) } else { onSelect(node) }
        } label: {
            VStack(spacing: diameter > 110 ? 7 : 4) {
                ZStack {
                    if node.isDirectory {
                        Image(systemName: "folder.fill")
                    } else {
                        Image(systemName: node.category.icon)
                    }
                }
                .font(.system(size: max(15, min(30, diameter * 0.19)), weight: .medium))

                Text(node.name)
                    .lineLimit(diameter > 120 ? 2 : 1)
                    .multilineTextAlignment(.center)
                    .truncationMode(.middle)
                    .zentraFont(max(8.5, min(11, diameter * 0.075)), weight: .semibold)
                    .padding(.horizontal, 9)

                Text(ByteCountFormatter.string(fromByteCount: node.totalBytes, countStyle: .file))
                    .zentraFont(max(7.5, min(9.5, diameter * 0.062)), weight: .medium)
                    .foregroundStyle(active ? Color.zentraBackground.opacity(0.72) : Color.zentraTextTertiary)

                if node.isDirectory && diameter > 105 {
                    Text(String(format: NSLocalizedString("storage.visual.files", comment: ""), node.fileCount))
                        .zentraFont(7.5)
                        .foregroundStyle(active ? Color.zentraBackground.opacity(0.6) : Color.zentraTextTertiary)
                }
            }
            .foregroundStyle(active ? Color.zentraBackground : Color.zentraTextPrimary)
            .frame(width: diameter, height: diameter)
            .background(
                Circle().fill(
                    RadialGradient(
                        colors: active
                            ? [Color.zentraAccent.opacity(0.96), Color.zentraAccent.opacity(0.78)]
                            : [Color.zentraAccent.opacity(node.isDirectory ? 0.18 : 0.11), Color.zentraAccent.opacity(0.045)],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: diameter * 0.7
                    )
                )
            )
            .overlay(Circle().stroke(Color.zentraAccent.opacity(active ? 0.95 : 0.38), lineWidth: active ? 2.5 : 1))
            .shadow(color: Color.black.opacity(0.22), radius: 14, y: 8)
            .shadow(color: Color.zentraAccent.opacity(active ? 0.18 : 0.06), radius: 18)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if node.isDirectory { Button("storage.action.explore") { onOpenDirectory(node) } }
            else { Button("storage.action.open") { onOpen(node) } }
            Button("storage.action.reveal") { onReveal(node) }
            if !node.isDirectory {
                Divider()
                Button("storage.action.trash", role: .destructive) { onTrash(node) }
            }
        }
        .help(node.url.path)
    }
}

private struct BubbleLayoutEntry: Identifiable {
    let node: StorageNode
    let center: CGPoint
    let diameter: CGFloat
    var id: URL { node.id }
}

private enum BubblePackingLayout {
    static func pack(nodes: [StorageNode], in size: CGSize) -> [BubbleLayoutEntry] {
        guard !nodes.isEmpty, size.width > 100, size.height > 100 else { return [] }

        let padding: CGFloat = 16
        let gap: CGFloat = 12
        let maxBytes = Double(max(nodes.map(\.totalBytes).max() ?? 1, 1))
        let minD: CGFloat = 72
        let maxD: CGFloat = min(190, max(125, size.width * 0.18))

        var placed: [BubbleLayoutEntry] = []
        var angle: CGFloat = 0
        var radius: CGFloat = 0
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        for node in nodes {
            let normalized = pow(Double(node.totalBytes) / maxBytes, 0.36)
            let diameter = minD + CGFloat(normalized) * (maxD - minD)
            var candidate = center
            var found = false

            for attempt in 0..<900 {
                if attempt == 0 && placed.isEmpty {
                    candidate = center
                } else {
                    angle += 0.43
                    radius += 0.34
                    candidate = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                }

                let inside = candidate.x - diameter/2 >= padding &&
                    candidate.x + diameter/2 <= size.width - padding &&
                    candidate.y - diameter/2 >= padding &&
                    candidate.y + diameter/2 <= size.height - padding

                let clear = placed.allSatisfy {
                    let dx = candidate.x - $0.center.x
                    let dy = candidate.y - $0.center.y
                    let required = (diameter + $0.diameter) / 2 + gap
                    return dx*dx + dy*dy >= required*required
                }

                if inside && clear { found = true; break }
            }

            if found { placed.append(BubbleLayoutEntry(node: node, center: candidate, diameter: diameter)) }
        }
        return placed
    }
}
