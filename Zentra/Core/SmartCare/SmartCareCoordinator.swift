import Foundation
import SwiftUI

@MainActor
final class SmartCareCoordinator: ObservableObject {
    @Published private(set) var state: SmartCareRunState = .idle
    @Published private(set) var progress: Double = 0
    @Published private(set) var scanProgress = ScanProgress(discoveredItems: 0, discoveredBytes: 0, currentURL: nil)
    @Published private(set) var summary: SmartCareSummary?

    private let scanner = FileSystemScanner()
    private let workspaceAnalyzer = WorkspaceCleanerAnalyzer()
    private let workspaceCatalog = WorkspaceCleanupCatalog()
    private let applicationScanner = ApplicationScanner()
    private let performanceMonitor = PerformanceMonitor()
    private let targetPolicy = ScanTargetPolicy()
    private var task: Task<Void, Never>?

    func start() {
        cancel()
        summary = nil
        progress = 0
        task = Task {
            do {
                state = .scanning(.cleanup)
                let scan = try await scanner.scan(targets: targetPolicy.smartCareTargets()) { [weak self] update in
                    await MainActor.run { self?.scanProgress = update }
                }
                try Task.checkCancellation()
                let review = await Task.detached(priority: .userInitiated) { ScanReviewBuilder().build(scan) }.value
                progress = 0.42

                state = .scanning(.workspace)
                let workspaceResults = await workspaceAnalyzer.analyze(workspaceCatalog.locations())
                try Task.checkCancellation()
                let workspace = Self.workspaceSummary(workspaceResults)
                progress = 0.68

                state = .scanning(.applications)
                let apps = try await applicationScanner.scan()
                try Task.checkCancellation()
                progress = 0.86

                state = .scanning(.performance)
                let performance = await performanceMonitor.snapshot()
                try Task.checkCancellation()
                progress = 1

                summary = SmartCareSummary(cleanup: review, workspace: workspace, applications: apps, performance: performance, completedAt: Date())
                state = .completed
            } catch is CancellationError {
                state = .cancelled
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        if case .scanning = state { state = .cancelled }
    }

    nonisolated private static func workspaceSummary(_ results: [WorkspaceCleanupResult]) -> SmartCareWorkspaceSummary {
        func bytes(_ safety: WorkspaceSafety) -> Int64 { results.filter { $0.location.safety == safety }.reduce(0) { $0 + $1.bytes } }
        func count(_ safety: WorkspaceSafety) -> Int { results.filter { $0.location.safety == safety && $0.bytes > 0 }.count }
        return .init(safeBytes: bytes(.safe), reviewBytes: bytes(.review), protectedBytes: bytes(.protected), safeCount: count(.safe), reviewCount: count(.review), protectedCount: count(.protected))
    }

    deinit { task?.cancel() }
}
