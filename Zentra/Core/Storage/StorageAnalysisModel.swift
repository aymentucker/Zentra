import Foundation
import SwiftUI

@MainActor
final class StorageAnalysisModel: ObservableObject {
    enum State: Equatable {
        case idle
        case scanning
        case completed
        case cancelled
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var fileCount = 0
    @Published private(set) var scannedBytes: Int64 = 0
    @Published private(set) var currentURL: URL?
    @Published private(set) var analysis: StorageAnalysis?

    private let analyzer = StorageAnalyzer()
    private var task: Task<Void, Never>?
    private var activeRoots: [URL] = []

    func start(roots requestedRoots: [URL]? = nil) {
        cancel()

        let roots: [URL]
        if let requestedRoots, !requestedRoots.isEmpty {
            roots = StorageTargetPolicy().normalized(requestedRoots)
        } else if !activeRoots.isEmpty {
            roots = activeRoots
        } else {
            roots = StorageTargetPolicy().defaultRoots()
        }

        activeRoots = roots
        state = .scanning
        analysis = nil
        fileCount = 0
        scannedBytes = 0
        currentURL = roots.first

        task = Task {
            do {
                let result = try await analyzer.analyze(roots: roots) { [weak self] count, bytes, url in
                    await MainActor.run {
                        self?.fileCount = count
                        self?.scannedBytes = bytes
                        if let url {
                            self?.currentURL = url
                        }
                    }
                }
                try Task.checkCancellation()
                analysis = result
                currentURL = nil
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
        if state == .scanning {
            state = .cancelled
        }
    }

    deinit {
        task?.cancel()
    }
}
