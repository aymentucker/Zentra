import Foundation
import SwiftUI
import AppKit

@MainActor
final class PerformanceModel: ObservableObject {
    @Published private(set) var snapshot: PerformanceSnapshot?
    @Published private(set) var isRefreshing = false
    @Published var errorMessage: String?
    private let monitor = PerformanceMonitor()
    private var refreshTask: Task<Void, Never>?

    func refresh() {
        refreshTask?.cancel()
        isRefreshing = true
        refreshTask = Task {
            let value = await monitor.snapshot()
            guard !Task.isCancelled else { return }
            snapshot = value
            isRefreshing = false
        }
    }

    func startAutoRefresh() {
        guard refreshTask == nil else { return }
        refreshTask = Task {
            while !Task.isCancelled {
                let value = await monitor.snapshot()
                guard !Task.isCancelled else { break }
                snapshot = value
                isRefreshing = false
                try? await Task.sleep(for: .seconds(4))
            }
        }
    }

    func stopAutoRefresh() { refreshTask?.cancel(); refreshTask = nil }
    func reveal(_ item: StartupItem) { NSWorkspace.shared.activateFileViewerSelecting([item.url]) }
}
