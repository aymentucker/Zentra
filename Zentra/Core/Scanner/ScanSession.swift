import Foundation
import SwiftUI

struct ScanReviewSnapshot: Sendable {
    let groups: [ScanCategory: [ClassifiedScanItem]]
    let counts: [ScanCategory: Int]
    let bytes: [ScanCategory: Int64]
    let totalBytes: Int64
}

@MainActor
final class ScanSession: ObservableObject {
    enum State: Equatable {
        case idle, scanning, preparingResults, completed, cancelled
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var progress = ScanProgress(discoveredItems: 0, discoveredBytes: 0, currentURL: nil)
    @Published private(set) var result: ScanSummary?
    @Published private(set) var review: ScanReviewSnapshot?

    private let scanner = FileSystemScanner()
    private var task: Task<Void, Never>?

    func start(targets: [ScanTarget]) {
        cancel()
        state = .scanning
        result = nil
        review = nil
        progress = ScanProgress(discoveredItems: 0, discoveredBytes: 0, currentURL: nil)

        task = Task {
            do {
                let summary = try await scanner.scan(targets: targets) { [weak self] update in
                    await MainActor.run { self?.progress = update }
                }
                try Task.checkCancellation()
                state = .preparingResults

                let snapshot = await Task.detached(priority: .userInitiated) {
                    Self.makeReviewSnapshot(summary)
                }.value

                try Task.checkCancellation()
                result = summary
                review = snapshot
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
        if state == .scanning || state == .preparingResults { state = .cancelled }
    }

    nonisolated private static func makeReviewSnapshot(_ summary: ScanSummary) -> ScanReviewSnapshot {
        let classified = ScanClassifier().classify(summary).filter { !$0.file.isDirectory }
        var allGroups: [ScanCategory: [ClassifiedScanItem]] = [:]
        var counts: [ScanCategory: Int] = [:]
        var bytes: [ScanCategory: Int64] = [:]

        for item in classified {
            counts[item.category, default: 0] += 1
            bytes[item.category, default: 0] += item.file.size
            allGroups[item.category, default: []].append(item)
        }

        var displayGroups: [ScanCategory: [ClassifiedScanItem]] = [:]
        for (category, items) in allGroups {
            displayGroups[category] = Array(items.sorted { $0.file.size > $1.file.size }.prefix(30))
        }

        return ScanReviewSnapshot(
            groups: displayGroups,
            counts: counts,
            bytes: bytes,
            totalBytes: classified.reduce(0) { $0 + $1.file.size }
        )
    }

    deinit { task?.cancel() }
}
