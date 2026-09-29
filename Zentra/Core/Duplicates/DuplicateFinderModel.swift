import Foundation
import SwiftUI

@MainActor
final class DuplicateFinderModel: ObservableObject {
    enum State { case idle, scanning, completed, cancelled, failed }

    @Published private(set) var state: State = .idle
    @Published private(set) var analysis: DuplicateAnalysis?
    @Published private(set) var files = 0
    @Published private(set) var bytes: Int64 = 0
    @Published private(set) var currentURL: URL?
    @Published var selected = Set<URL>()
    @Published var errorMessage: String?

    private let finder = DuplicateFinder()
    private var task: Task<Void, Never>?
    private var scanRoots: [URL] = []

    func start(roots: [URL]) {
        cancel()
        scanRoots = roots
        analysis = nil
        selected = []
        files = 0
        bytes = 0
        currentURL = nil
        errorMessage = nil
        state = .scanning

        task = Task {
            do {
                let result = try await finder.find(roots: roots) { [weak self] count, size, url in
                    await MainActor.run {
                        self?.files = count
                        self?.bytes = size
                        self?.currentURL = url
                    }
                }
                try Task.checkCancellation()
                analysis = result
                state = .completed
                for group in result.groups {
                    selected.formUnion(group.files.dropFirst().map(\.url))
                }
            } catch is CancellationError {
                state = .cancelled
            } catch {
                errorMessage = error.localizedDescription
                state = .failed
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        if state == .scanning { state = .cancelled }
    }

    func toggle(_ url: URL) {
        if selected.contains(url) { selected.remove(url) }
        else { selected.insert(url) }
    }

    func safeSelected(in group: DuplicateGroup) -> [DuplicateFile] {
        let chosen = group.files.filter { selected.contains($0.url) }
        return chosen.count >= group.files.count ? Array(chosen.dropLast()) : chosen
    }

    func trashSelected() {
        guard let analysis else { return }
        for group in analysis.groups {
            for file in safeSelected(in: group) {
                do {
                    _ = try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)
                    selected.remove(file.url)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }

        // Re-scan only after a fully successful cleanup. If any item could not
        // be moved, keep the current results and surface the failure so the user
        // can review exactly what remains instead of erasing the operation error.
        if errorMessage == nil, !scanRoots.isEmpty {
            start(roots: scanRoots)
        }
    }
}
