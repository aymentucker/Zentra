import SwiftUI

enum AppDestination: String, CaseIterable, Hashable {
    case smartCare, cleanup, storage, duplicates, tidyUp
    case applications, performance, developer, settings

    var titleKey: LocalizedStringKey {
        switch self {
        case .smartCare: "nav.smartCare"
        case .cleanup: "nav.cleanup"
        case .storage: "nav.storage"
        case .duplicates: "nav.duplicates"
        case .tidyUp: "nav.tidy"
        case .applications: "nav.applications"
        case .performance: "nav.performance"
        case .developer: "nav.developer"
        case .settings: "nav.settings"
        }
    }

    var iconName: String {
        switch self {
        case .smartCare: "smart-care"
        case .cleanup: "cleanup"
        case .storage: "storage"
        case .duplicates: "duplicates"
        case .tidyUp: "tidy"
        case .applications: "applications"
        case .performance: "performance"
        case .developer: "developer"
        case .settings: "settings"
        }
    }
}
