import Foundation
import SwiftUI

@MainActor
final class CleanupSourceAnalysisModel: ObservableObject {
    @Published private(set) var summaries: [CleanupSourceKind: CleanupSourceSummary] = [:]
    @Published private(set) var isAnalyzing = false

    private let analyzer = CleanupSourceAnalyzer()
    private var task: Task<Void, Never>?

    func start(sources: [CleanupSource]) {
        task?.cancel()
        isAnalyzing = true
        task = Task {
            let values = await analyzer.analyze(sources)
            guard !Task.isCancelled else { return }
            summaries = Dictionary(uniqueKeysWithValues: values.map { ($0.source.kind, $0) })
            isAnalyzing = false
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        isAnalyzing = false
    }

    deinit { task?.cancel() }
}
