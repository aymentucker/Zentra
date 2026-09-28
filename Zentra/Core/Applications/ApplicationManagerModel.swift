import Foundation
import SwiftUI
import AppKit

@MainActor
final class ApplicationManagerModel: ObservableObject {
    enum State { case idle, scanning, ready, failed }
    @Published private(set) var state: State = .idle
    @Published private(set) var inventory: ApplicationInventory?
    @Published private(set) var preview: ApplicationRemovalPreview?
    @Published var selectedArtifacts = Set<URL>()
    @Published var searchText = ""
    @Published var errorMessage: String?
    @Published private(set) var isRemoving = false

    private let scanner = ApplicationScanner()
    private let artifactFinder = ApplicationArtifactFinder()
    private let executor = ApplicationRemovalExecutor()
    private var task: Task<Void, Never>?

    var filteredApplications: [InstalledApplication] {
        guard let apps = inventory?.applications else { return [] }
        guard !searchText.isEmpty else { return apps }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || ($0.bundleIdentifier?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    func scan() {
        task?.cancel()
        state = .scanning
        errorMessage = nil
        task = Task {
            do {
                inventory = try await scanner.scan()
                try Task.checkCancellation()
                state = .ready
            } catch is CancellationError {
                state = .idle
            } catch {
                errorMessage = error.localizedDescription
                state = .failed
            }
        }
    }

    func inspect(_ app: InstalledApplication) {
        task?.cancel()
        preview = nil
        selectedArtifacts = []
        task = Task {
            let result = await artifactFinder.preview(for: app)
            preview = result
            selectedArtifacts = Set(result.artifacts.filter { $0.confidence >= 1 }.map(\.url))
        }
    }

    func closePreview() { preview = nil; selectedArtifacts = [] }

    func toggleArtifact(_ url: URL) {
        if selectedArtifacts.contains(url) { selectedArtifacts.remove(url) }
        else { selectedArtifacts.insert(url) }
    }

    func reveal(_ url: URL) { NSWorkspace.shared.activateFileViewerSelecting([url]) }
    func open(_ url: URL) { NSWorkspace.shared.open(url) }

    func uninstall() {
        guard let preview, preview.application.safety != .protected else { return }
        isRemoving = true
        let selected = selectedArtifacts
        Task {
            let result = await executor.execute(preview: preview, includeArtifacts: selected)
            isRemoving = false
            if !result.failed.isEmpty {
                errorMessage = "applications.error.partial"
            }
            closePreview()
            scan()
        }
    }
}
