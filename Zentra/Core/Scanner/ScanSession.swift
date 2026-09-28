import Foundation
import SwiftUI

@MainActor
final class ScanSession: ObservableObject {
    enum State: Equatable {
        case idle
        case scanning
        case completed
        case failed(String)
        case cancelled
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var progress = ScanProgress(discoveredItems: 0, discoveredBytes: 0, currentURL: nil)
    @Published private(set) var result: ScanSummary?

    private let scanner = FileSystemScanner()
    private var task: Task<Void, Never>?

    func start(targets: [ScanTarget]) {
        cancel()
        state = .scanning
        result = nil
        progress = ScanProgress(discoveredItems: 0, discoveredBytes: 0, currentURL: nil)

        task = Task {
            do {
                let summary = try await scanner.scan(targets: targets) { [weak self] update in
                    await MainActor.run { self?.progress = update }
                }
                guard !Task.isCancelled else { return }
                result = summary
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
        if state == .scanning { state = .cancelled }
    }

    deinit { task?.cancel() }
}
