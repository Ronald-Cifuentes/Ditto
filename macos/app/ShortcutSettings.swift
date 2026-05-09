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
        .init(commandID: "show_ditto", commandName: "Show Quick Paste", primary: "Command-Option-V", secondary: "", scope: "Global"),
        .init(commandID: "capture_now", commandName: "Save Current Clipboard", primary: "Command-Shift-C", secondary: "", scope: "App"),
        .init(commandID: "paste_selected", commandName: "Paste Selected", primary: "Command-Return", secondary: "", scope: "App"),
        .init(commandID: "copy_latest", commandName: "Copy Latest", primary: "Command-Shift-V", secondary: "", scope: "App"),
        .init(commandID: "delete_selected", commandName: "Delete Selected", primary: "Delete", secondary: "", scope: "App"),
        .init(commandID: "refresh_list", commandName: "Refresh List", primary: "Command-R", secondary: "", scope: "App"),
        .init(commandID: "new_group", commandName: "New Group", primary: "F7", secondary: "", scope: "Quick Paste"),
        .init(commandID: "new_group_selection", commandName: "New Group Selection", primary: "Control-F7", secondary: "", scope: "Quick Paste"),
        .init(commandID: "back_group", commandName: "Back Group", primary: "Backspace", secondary: "", scope: "Quick Paste"),
        .init(commandID: "plain_text", commandName: "Paste Selected Plain Text", primary: "", secondary: "", scope: "Quick Paste"),
        .init(commandID: "upper_case", commandName: "Paste Upper Case", primary: "", secondary: "", scope: "Special Paste"),
        .init(commandID: "lower_case", commandName: "Paste Lower Case", primary: "", secondary: "", scope: "Special Paste"),
        .init(commandID: "sentence_case", commandName: "Paste Sentence Case", primary: "", secondary: "", scope: "Special Paste"),
        .init(commandID: "trim_whitespace", commandName: "Paste Trim White Space", primary: "", secondary: "", scope: "Special Paste"),
        .init(commandID: "slugify", commandName: "Slugify", primary: "", secondary: "", scope: "Special Paste"),
        .init(commandID: "position_1", commandName: "Paste Position 1", primary: "Command-1", secondary: "", scope: "First Ten"),
        .init(commandID: "position_2", commandName: "Paste Position 2", primary: "Command-2", secondary: "", scope: "First Ten"),
        .init(commandID: "position_3", commandName: "Paste Position 3", primary: "Command-3", secondary: "", scope: "First Ten"),
        .init(commandID: "position_4", commandName: "Paste Position 4", primary: "Command-4", secondary: "", scope: "First Ten"),
        .init(commandID: "position_5", commandName: "Paste Position 5", primary: "Command-5", secondary: "", scope: "First Ten"),
        .init(commandID: "position_6", commandName: "Paste Position 6", primary: "Command-6", secondary: "", scope: "First Ten"),
        .init(commandID: "position_7", commandName: "Paste Position 7", primary: "Command-7", secondary: "", scope: "First Ten"),
        .init(commandID: "position_8", commandName: "Paste Position 8", primary: "Command-8", secondary: "", scope: "First Ten"),
        .init(commandID: "position_9", commandName: "Paste Position 9", primary: "Command-9", secondary: "", scope: "First Ten"),
        .init(commandID: "position_10", commandName: "Paste Position 10", primary: "Command-0", secondary: "", scope: "First Ten")
    ]
}
