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
    @Published var manualRemovalURL: URL?
    @Published private(set) var pendingAuthorizedRemoval: ApplicationRemovalPreview?
    @Published private(set) var pendingAuthorizedArtifacts = Set<URL>()
    @Published private(set) var authorizationState: ApplicationRemovalAuthorizationState = .notRegistered

    private let scanner = ApplicationScanner()
    private let artifactFinder = ApplicationArtifactFinder()
    private let executor = ApplicationRemovalExecutor()
    private let authorization = ApplicationRemovalAuthorization()
    private let authorizedClient = AuthorizedApplicationRemovalClient()
    private var task: Task<Void, Never>?

    var filteredApplications: [InstalledApplication] {
        guard let apps = inventory?.applications else { return [] }
        guard !searchText.isEmpty else { return apps }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || ($0.bundleIdentifier?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    func refreshAuthorization() {
        authorization.refresh()
        authorizationState = authorization.state
    }

    func requestRemovalAuthorization() {
        authorization.requestRegistration()
        authorizationState = authorization.state
        if let registrationError = authorization.errorMessage {
            errorMessage = registrationError
        }
        if authorization.state == .requiresApproval {
            authorization.openApprovalSettings()
        }
    }

    func dismissAuthorizationPrompt() {
        pendingAuthorizedRemoval = nil
        pendingAuthorizedArtifacts = []
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

    func revealManualRemoval() {
        guard let url = manualRemovalURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
        manualRemovalURL = nil
    }
    func open(_ url: URL) { NSWorkspace.shared.open(url) }

    func uninstall(_ request: ApplicationRemovalPreview, selectedArtifacts selected: Set<URL>) {
        guard request.application.safety != .protected else { return }
        isRemoving = true
        Task {
            let result = await executor.execute(preview: request, includeArtifacts: selected)
            isRemoving = false
            if result.applicationNeedsManualRemoval {
                pendingAuthorizedRemoval = request
                pendingAuthorizedArtifacts = selected
                refreshAuthorization()
            } else if !result.failed.isEmpty {
                let failedNames = result.failed.map(\.lastPathComponent).joined(separator: ", ")
                errorMessage = ZentraLocalization.format("applications.error.partial.detail", failedNames)
            }
            scan()
        }
    }

    func retryWithAuthorization() {
        guard let request = pendingAuthorizedRemoval else { return }
        refreshAuthorization()
        guard authorizationState == .enabled else {
            requestRemovalAuthorization()
            return
        }

        isRemoving = true
        Task {
            do {
                try await authorizedClient.remove(request.application)
                // The service is required to verify that the app bundle is gone.
                guard !FileManager.default.fileExists(atPath: request.application.url.path) else {
                    throw AuthorizedRemovalClientError.rejected("verification_failed")
                }
                // Privileged service removes only the app bundle. Leftovers stay
                // in the normal user-context cleanup path.
                let artifacts = pendingAuthorizedArtifacts
                pendingAuthorizedRemoval = nil
                pendingAuthorizedArtifacts = []
                isRemoving = false
                let followup = await executor.executeArtifactsOnly(preview: request, includeArtifacts: artifacts)
                if !followup.failed.isEmpty {
                    let names = followup.failed.map(\.lastPathComponent).joined(separator: ", ")
                    errorMessage = ZentraLocalization.format("applications.error.partial.detail", names)
                }
                scan()
            } catch {
                isRemoving = false
                errorMessage = error.localizedDescription
            }
        }
    }

    func useFinderFallback() {
        guard let request = pendingAuthorizedRemoval else { return }
        manualRemovalURL = request.application.url
        pendingAuthorizedRemoval = nil
        pendingAuthorizedArtifacts = []
    }
}
