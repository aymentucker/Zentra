import Foundation
import Combine
import ServiceManagement

enum ApplicationRemovalAuthorizationState: Equatable, Sendable {
    case notRegistered
    case enabled
    case requiresApproval
    case unavailable
}

@MainActor
final class ApplicationRemovalAuthorization: ObservableObject {
    static let daemonPlistName = "com.zentra.app.removal-service.plist"

    @Published private(set) var state: ApplicationRemovalAuthorizationState = .notRegistered
    @Published var errorMessage: String?

    private var service: SMAppService {
        .daemon(plistName: Self.daemonPlistName)
    }

    static func map(_ status: SMAppService.Status) -> ApplicationRemovalAuthorizationState {
        switch status {
        case .enabled: return .enabled
        case .requiresApproval: return .requiresApproval
        case .notRegistered: return .notRegistered
        case .notFound: return .unavailable
        @unknown default: return .unavailable
        }
    }

    func refresh() {
        state = Self.map(service.status)
    }

    func requestRegistration() {
        errorMessage = nil
        do {
            try service.register()
            refresh()
        } catch {
            errorMessage = error.localizedDescription
            refresh()
        }
    }

    func openApprovalSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
