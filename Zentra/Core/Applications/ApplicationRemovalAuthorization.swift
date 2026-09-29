import Foundation
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

    func refresh() {
        switch service.status {
        case .enabled: state = .enabled
        case .requiresApproval: state = .requiresApproval
        case .notRegistered: state = .notRegistered
        case .notFound: state = .unavailable
        @unknown default: state = .unavailable
        }
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
