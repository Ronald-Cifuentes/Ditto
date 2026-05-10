import Foundation

enum ClipKind: String {
    case text
    case image
    case files
    case rtf
    case html

    var label: String {
        switch self {
        case .text:
            return "Text"
        case .image:
            return "Image"
        case .files:
            return "Files"
        case .rtf:
            return "RTF"
        case .html:
            return "HTML"
        }
    }

    var symbolName: String {
        switch self {
        case .text:
            return "text.alignleft"
        case .image:
            return "photo"
        case .files:
            return "folder"
        case .rtf:
            return "doc.richtext"
        case .html:
            return "chevron.left.forwardslash.chevron.right"
        }
    }
}

struct ClipboardPayload: Hashable {
    let kind: ClipKind
    let content: String
    let payload: Data?
    let metadata: String
}

struct ClipItem: Identifiable, Hashable {
    let id: Int64
    let createdAt: String
    let kind: ClipKind
    let content: String
    let payload: Data?
    let metadata: String
    let groupName: String
    let isFavorite: Bool

    var preview: String {
        if content.isEmpty {
            return kind.label
        }
        return PreviewText.make(from: content, maxLength: 140)
    }

    var filePaths: [String] {
        guard kind == .files else {
            return []
        }
        return content
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
    }
}

enum DittoMacPaths {
    static func configuredDatabasePath() throws -> String {
        if let configured = ProcessInfo.processInfo.environment["DITTO_MAC_DB"],
           !configured.isEmpty {
            return configured
        }

        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("DittoMac")
            .appendingPathComponent("history.sqlite")
            .path
    }
}

enum PreviewText {
    static func make(from text: String, maxLength: Int) -> String {
        var result = ""
        result.reserveCapacity(min(text.count, maxLength))

        for scalar in text.unicodeScalars {
            switch scalar {
            case "\n":
                result += "\\n"
            case "\r":
                result += "\\r"
            case "\t":
                result += "\\t"
            case "\0":
                result += "\\0"
            default:
                result.unicodeScalars.append(scalar)
            }

            if result.count > maxLength {
                return String(result.prefix(max(0, maxLength - 3))) + "..."
            }
        }

        return result
    }
}
