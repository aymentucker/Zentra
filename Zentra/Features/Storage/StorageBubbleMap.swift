import SwiftUI

struct StorageBubbleMap: View {
    let items: [StorageItem]
    let selected: Set<URL>
    let onToggle: (StorageItem) -> Void
    let onReveal: (StorageItem) -> Void
    let onOpen: (StorageItem) -> Void
    let onTrash: (StorageItem) -> Void

    private var visible: [StorageItem] { Array(items.prefix(28)) }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 22).fill(Color.zentraSurface)
                ForEach(Array(visible.enumerated()), id: \.element.id) { index, item in
                    bubble(item, index: index, size: proxy.size)
                }
            }
            .clipped()
        }
        .frame(minHeight: 440)
    }

    private func bubble(_ item: StorageItem, index: Int, size: CGSize) -> some View {
        let maxBytes = Double(max(visible.first?.size ?? 1, 1))
        let ratio = sqrt(Double(item.size) / maxBytes)
        let diameter = max(64, min(154, 62 + ratio * 92))
        let point = position(index, in: size, diameter: diameter)
        return Button { onToggle(item) } label: {
            VStack(spacing: 5) {
                Image(systemName: item.category.icon).font(.system(size: diameter > 105 ? 24 : 17, weight: .medium))
                Text(item.url.lastPathComponent).lineLimit(1).truncationMode(.middle).zentraFont(diameter > 105 ? 10 : 8.5, weight: .medium)
                Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file)).zentraFont(8).opacity(0.7)
            }
            .foregroundStyle(selected.contains(item.id) ? Color.zentraBackground : Color.zentraTextPrimary)
            .frame(width: diameter, height: diameter)
            .background(Circle().fill(selected.contains(item.id) ? Color.zentraAccent : Color.zentraAccent.opacity(0.13)))
            .overlay(Circle().stroke(Color.zentraAccent.opacity(selected.contains(item.id) ? 1 : 0.5), lineWidth: selected.contains(item.id) ? 3 : 1))
            .shadow(color: Color.zentraAccent.opacity(0.12), radius: 14)
        }
        .buttonStyle(.plain)
        .position(point)
        .contextMenu {
            Button("storage.action.open") { onOpen(item) }
            Button("storage.action.reveal") { onReveal(item) }
            Divider()
            Button("storage.action.trash", role: .destructive) { onTrash(item) }
        }
    }

    private func position(_ index: Int, in size: CGSize, diameter: CGFloat) -> CGPoint {
        let columns = max(2, Int(size.width / 175))
        let row = index / columns
        let column = index % columns
        let cellW = size.width / CGFloat(columns)
        let x = cellW * (CGFloat(column) + 0.5) + CGFloat((row + column) % 2) * 12 - 6
        let y = 92 + CGFloat(row) * 155 + CGFloat(column % 2) * 24
        return CGPoint(x: min(max(diameter / 2 + 8, x), size.width - diameter / 2 - 8), y: y)
    }
}
