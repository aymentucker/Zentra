import Foundation
import SwiftUI
import AppKit

@MainActor
final class StorageSelectionModel: ObservableObject {
    @Published var selected = Set<URL>()
    @Published private(set) var isDeleting = false
    @Published var errorMessage: String?

    func toggle(_ item: StorageItem) {
        if selected.contains(item.id) { selected.remove(item.id) } else { selected.insert(item.id) }
    }

    func clear() { selected.removeAll() }

    func select(_ urls: [URL]) { selected.formUnion(urls) }

    func reveal(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    func open(_ url: URL) { NSWorkspace.shared.open(url) }

    func moveToTrash(_ items: [StorageItem], onComplete: @escaping () -> Void) {
        guard !items.isEmpty, !isDeleting else { return }
        isDeleting = true
        errorMessage = nil
        Task {
            var failures = 0
            for item in items {
                do {
                    _ = try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
                    selected.remove(item.id)
                } catch { failures += 1 }
            }
            isDeleting = false
            if failures > 0 { errorMessage = "\(failures) item(s) could not be moved to Trash." }
            onComplete()
        }
    }
}
