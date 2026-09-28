import Foundation
import SwiftUI

@MainActor
final class CleanupConfirmationModel: ObservableObject {
    enum State: Equatable {
        case idle, confirming, executing, completed
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var report: CleanupExecutionReport?

    private let executor: CleanupExecutor
    private var task: Task<Void, Never>?

    init(executor: CleanupExecutor = CleanupExecutor()) {
        self.executor = executor
    }

    func requestConfirmation() {
        guard state != .executing else { return }
        state = .confirming
    }

    func dismissConfirmation() {
        guard state == .confirming else { return }
        state = .idle
    }

    func execute(_ plan: CleanupPlan) {
        guard state != .executing else { return }
        state = .executing
        report = nil

        task = Task {
            let result = await executor.execute(plan)
            guard !Task.isCancelled else {
                state = .idle
                return
            }
            report = result
            state = .completed
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    deinit { task?.cancel() }
}
