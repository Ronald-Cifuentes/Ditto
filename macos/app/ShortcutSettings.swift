import Foundation

struct ShortcutAssignment: Codable, Identifiable, Hashable {
    var id: String { commandID }
    let commandID: String
    var commandName: String
    var primary: String
    var secondary: String
    var scope: String
}

@MainActor
final class ShortcutSettingsStore: ObservableObject {
    @Published var assignments: [ShortcutAssignment] = [] {
        didSet {
            save()
        }
    }

    private let defaultsKey = "DittoMacShortcutAssignments"

    init() {
        load()
    }

    func resetToDefaults() {
        assignments = Self.defaultAssignments
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey),
              let decoded = try? JSONDecoder().decode([ShortcutAssignment].self, from: data) else {
            assignments = Self.defaultAssignments
            return
        }
        assignments = mergeWithDefaults(decoded)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(assignments) else {
            return
        }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func mergeWithDefaults(_ stored: [ShortcutAssignment]) -> [ShortcutAssignment] {
        var byID = Dictionary(uniqueKeysWithValues: stored.map { ($0.commandID, $0) })
        return Self.defaultAssignments.map { fallback in
            var item = byID.removeValue(forKey: fallback.commandID) ?? fallback
            item.commandName = fallback.commandName
            item.scope = fallback.scope
            return item
        }
    }

    static let defaultAssignments: [ShortcutAssignment] = [
        assignment("show_ditto", "Show Quick Paste", "Command-Option-V", scope: "Global"),
        assignment("capture_now", "Save Current Clipboard", "Command-Shift-C", scope: "App"),
        assignment("paste_selected", "Paste Selected", "Command-Return", scope: "App"),
        assignment("copy_latest", "Copy Latest", "Command-Shift-V", scope: "App"),
        assignment("delete_selected", "Delete Selected", "Delete", scope: "App"),
        assignment("refresh_list", "Refresh List", "Command-R", scope: "App"),
        assignment("new_group", "New Group", "F7", scope: "Quick Paste"),
        assignment("new_group_selection", "New Group Selection", "Control-F7", scope: "Quick Paste"),
        assignment("back_group", "Back Group", "Backspace", scope: "Quick Paste"),
        assignment("plain_text", "Paste Selected Plain Text", scope: "Quick Paste"),
        assignment("upper_case", "Paste Upper Case", scope: "Special Paste"),
        assignment("lower_case", "Paste Lower Case", scope: "Special Paste"),
        assignment("sentence_case", "Paste Sentence Case", scope: "Special Paste"),
        assignment("trim_whitespace", "Paste Trim White Space", scope: "Special Paste"),
        assignment("slugify", "Slugify", scope: "Special Paste"),
        assignment("position_1", "Paste Position 1", "Command-1", scope: "First Ten"),
        assignment("position_2", "Paste Position 2", "Command-2", scope: "First Ten"),
        assignment("position_3", "Paste Position 3", "Command-3", scope: "First Ten"),
        assignment("position_4", "Paste Position 4", "Command-4", scope: "First Ten"),
        assignment("position_5", "Paste Position 5", "Command-5", scope: "First Ten"),
        assignment("position_6", "Paste Position 6", "Command-6", scope: "First Ten"),
        assignment("position_7", "Paste Position 7", "Command-7", scope: "First Ten"),
        assignment("position_8", "Paste Position 8", "Command-8", scope: "First Ten"),
        assignment("position_9", "Paste Position 9", "Command-9", scope: "First Ten"),
        assignment("position_10", "Paste Position 10", "Command-0", scope: "First Ten")
    ]

    private static func assignment(
        _ commandID: String,
        _ commandName: String,
        _ primary: String = "",
        secondary: String = "",
        scope: String
    ) -> ShortcutAssignment {
        ShortcutAssignment(
            commandID: commandID,
            commandName: commandName,
            primary: primary,
            secondary: secondary,
            scope: scope
        )
    }
}
