import SwiftUI

struct StorageBubbleMap: View {
    let nodes: [StorageNode]
    let selected: Set<URL>
    let onSelect: (StorageNode) -> Void
    let onOpenDirectory: (StorageNode) -> Void
    let onReveal: (StorageNode) -> Void
    let onOpen: (StorageNode) -> Void
    let onTrash: (StorageNode) -> Void

    private var visible: [StorageNode] { Array(nodes.prefix(30)) }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 22).fill(Color.zentraSurface)
                if visible.isEmpty {
                    Text("storage.visual.empty").zentraFont(11).foregroundStyle(Color.zentraTextTertiary)
                }
                ForEach(Array(visible.enumerated()), id: \.element.id) { index, node in
                    bubble(node, index: index, size: proxy.size)
                }
            }.clipped()
        }.frame(minHeight: 470)
    }

    private func bubble(_ node: StorageNode, index: Int, size: CGSize) -> some View {
        let maxBytes = Double(max(visible.first?.totalBytes ?? 1, 1))
        let ratio = sqrt(Double(node.totalBytes) / maxBytes)
        let diameter = max(68, min(160, 64 + ratio * 96))
        let point = position(index, in: size, diameter: diameter)
        return Button {
            if node.isDirectory { onOpenDirectory(node) } else { onSelect(node) }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: node.isDirectory ? "folder.fill" : node.category.icon).font(.system(size: diameter > 110 ? 25 : 17, weight: .medium))
                Text(node.name).lineLimit(1).truncationMode(.middle).zentraFont(diameter > 110 ? 10 : 8.5, weight: .medium)
                Text(ByteCountFormatter.string(fromByteCount: node.totalBytes, countStyle: .file)).zentraFont(8).opacity(0.72)
                if node.isDirectory { Text("\(node.fileCount)").zentraFont(7.5).opacity(0.55) }
            }
            .foregroundStyle(selected.contains(node.id) ? Color.zentraBackground : Color.zentraTextPrimary)
            .frame(width: diameter, height: diameter)
            .background(Circle().fill(selected.contains(node.id) ? Color.zentraAccent : Color.zentraAccent.opacity(node.isDirectory ? 0.18 : 0.11)))
            .overlay(Circle().stroke(Color.zentraAccent.opacity(selected.contains(node.id) ? 1 : 0.48), lineWidth: selected.contains(node.id) ? 3 : 1))
            .shadow(color: Color.zentraAccent.opacity(0.13), radius: 14)
        }
        .buttonStyle(.plain).position(point)
        .contextMenu {
            if node.isDirectory { Button("storage.action.explore") { onOpenDirectory(node) } }
            else { Button("storage.action.open") { onOpen(node) } }
            Button("storage.action.reveal") { onReveal(node) }
            if !node.isDirectory { Divider(); Button("storage.action.trash", role: .destructive) { onTrash(node) } }
        }
    }

    private func position(_ index: Int, in size: CGSize, diameter: CGFloat) -> CGPoint {
        let columns = max(2, Int(size.width / 180))
        let row = index / columns, column = index % columns
        let cellW = size.width / CGFloat(columns)
        let x = cellW * (CGFloat(column) + 0.5) + CGFloat((row + column) % 2) * 14 - 7
        let y = 92 + CGFloat(row) * 160 + CGFloat(column % 2) * 25
        return CGPoint(x: min(max(diameter / 2 + 8, x), size.width - diameter / 2 - 8), y: y)
    }
}
