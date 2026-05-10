import Foundation

enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case shortcuts
    case quickPaste
    case types
    case copyBuffers
    case friends
    case database
    case parity
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            return "General"
        case .shortcuts:
            return "Shortcuts"
        case .quickPaste:
            return "Quick Paste"
        case .types:
            return "Types"
        case .copyBuffers:
            return "Copy Buffers"
        case .friends:
            return "Friends"
        case .database:
            return "Database"
        case .parity:
            return "Parity"
        case .about:
            return "About"
        }
    }

    var symbolName: String {
        switch self {
        case .general:
            return "gearshape"
        case .shortcuts:
            return "keyboard"
        case .quickPaste:
            return "list.bullet.rectangle"
        case .types:
            return "doc.on.clipboard"
        case .copyBuffers:
            return "tray.2"
        case .friends:
            return "network"
        case .database:
            return "externaldrive"
        case .parity:
            return "checklist"
        case .about:
            return "info.circle"
        }
    }
}
