import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: ClipboardHistoryModel
    @StateObject private var shortcuts = ShortcutSettingsStore()
    @State private var selectedSection = SettingsSection.general

    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width < 640 {
                compactSettings
            } else {
                tabbedSettings
            }
        }
        .frame(minWidth: 460, idealWidth: 820, minHeight: 430, idealHeight: 600)
    }
}

private extension SettingsView {
    var tabbedSettings: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }
            shortcutsTab
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
            quickPasteTab
                .tabItem { Label("Quick Paste", systemImage: "list.bullet.rectangle") }
            supportedTypesTab
                .tabItem { Label("Types", systemImage: "doc.on.clipboard") }
            copyBuffersTab
                .tabItem { Label("Copy Buffers", systemImage: "tray.2") }
            friendsTab
                .tabItem { Label("Friends", systemImage: "network") }
            maintenanceTab
                .tabItem { Label("Database", systemImage: "externaldrive") }
            parityTab
                .tabItem { Label("Parity", systemImage: "checklist") }
            aboutTab
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .padding(20)
    }

    var compactSettings: some View {
        VStack(spacing: 12) {
            Picker("Settings", selection: $selectedSection) {
                ForEach(SettingsSection.allCases) { section in
                    Label(section.title, systemImage: section.symbolName)
                        .tag(section)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            ScrollView {
                selectedSectionView
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
    }

    @ViewBuilder
    var selectedSectionView: some View {
        switch selectedSection {
        case .general:
            generalTab
        case .shortcuts:
            shortcutsTab
        case .quickPaste:
            quickPasteTab
        case .types:
            supportedTypesTab
        case .copyBuffers:
            copyBuffersTab
        case .friends:
            friendsTab
        case .database:
            maintenanceTab
        case .parity:
            parityTab
        case .about:
            aboutTab
        }
    }
}

private extension SettingsView {
    var generalTab: some View {
        Form {
            Toggle("Monitor Clipboard", isOn: $model.isMonitoring)
            Toggle("Global Hotkey: Command-Option-V", isOn: $model.isGlobalHotKeyEnabled)

            Section("Appearance") {
                LabeledContent("Theme", value: "System")
                LabeledContent("Popup position", value: "Previous window / active display")
                Text(
                    "Windows theme engine, caption docking, roll-up, transparency, " +
                        "and custom non-client painting are not ported yet."
                )
                    .foregroundStyle(.secondary)
            }

            Section("History") {
                HStack {
                    Text("\(model.clips.count) saved clips")
                    Spacer()
                    Button("Clear History", role: .destructive, action: model.clearHistory)
                        .disabled(model.clips.isEmpty)
                }
            }
        }
    }

    var shortcutsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) {
                    shortcutIntro
                    Spacer(minLength: 12)
                    Button("Reset Defaults", action: shortcuts.resetToDefaults)
                }
                VStack(alignment: .leading, spacing: 4) {
                    shortcutIntro
                    Button("Reset Defaults", action: shortcuts.resetToDefaults)
                }
            }

            List {
                ForEach($shortcuts.assignments) { $assignment in
                    ShortcutAssignmentRow(assignment: $assignment)
                        .padding(.vertical, 4)
                }
            }
            .frame(minHeight: 260)
        }
    }

    var shortcutIntro: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Shortcut Creation")
                .font(.title3)
                .fontWeight(.semibold)
            Text(
                "This mirrors the Windows Quick Paste Keyboard page structurally. " +
                    "Assignments are persisted; only the app-level commands and " +
                    "Command-Option-V global hotkey are currently wired."
            )
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private extension SettingsView {
    var quickPasteTab: some View {
        Form {
            Section("Window") {
                LabeledContent("Search", value: "Description/content/kind/group")
                LabeledContent("Groups", value: "Sidebar groups and favorites")
                LabeledContent("Paste selected", value: "Copies selected clip and sends Command-V")
            }

            Section("Missing Windows Quick Paste Options") {
                missing("First-ten accelerator rendering and per-position global hotkey behavior")
                missing("Show clip-was-pasted indicator")
                missing("Caption side selection, roll-up, transparency menu, and persistent custom frame")
                missing("Mouse shortcut assignment: click, double-click, right-click, middle-click")
                missing("Multi-selection paste aggregation")
                missing("Sticky clip ordering and top/last sticky replacement")
            }
        }
    }

    var supportedTypesTab: some View {
        Form {
            Section("Implemented Types") {
                LabeledContent("Text", value: "Stored/restored")
                LabeledContent("Images", value: "Stored/restored")
                LabeledContent("File URLs", value: "Stored/restored")
                LabeledContent("RTF", value: "Stored/restored")
                LabeledContent("HTML", value: "Stored/restored")
            }

            Section("Missing Windows Type Configuration") {
                missing("Add/remove arbitrary clipboard format names like the Windows Types table")
                missing(
                    "Windows-specific CF_DIB, CF_HDROP internals, registered format " +
                        "names, and delayed OLE rendering"
                )
                missing("Per-type capture enable/disable persistence")
            }
        }
    }

    var copyBuffersTab: some View {
        Form {
            Section("Windows Copy Buffers") {
                missing("Three named copy/cut/paste buffers")
                missing("Per-buffer copy, paste, and cut global hotkeys")
                missing("Play sound on copy per buffer")
                missing("Conflict detection between buffer hotkeys and main Ditto hotkeys")
            }
        }
    }

    var friendsTab: some View {
        Form {
            Section("Network Friends") {
                missing("Friend list configuration")
                missing("Send-to-friend actions 1-15")
                missing("Encrypted network clip transfer")
                missing("Auto-send client count, IP allow list, port, password, and send/receive logging")
            }
        }
    }

    var maintenanceTab: some View {
        Form {
            Section("Storage") {
                Text(model.databasePath)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .lineLimit(3)

                Button(action: model.revealDatabase) {
                    Label("Reveal Database", systemImage: "folder")
                }
            }

            Section("Missing Windows Maintenance") {
                missing("Backup database")
                missing("Restore database")
                missing("Delete clip data dialog")
                missing("Delete all non-used clips")
                missing("Import/export .dto clips and legacy database conversion")
            }
        }
    }
}

private extension SettingsView {
    var parityTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Windows Menus Still Missing Or Partial")
                    .font(.title3)
                    .fontWeight(.semibold)
                parity(
                    "Tray/system menu",
                    "Startup message, connect/disconnect clipboard, backup/restore, " +
                        "import, new clip, delete unused clips."
                )
                parity(
                    "Quick Paste context menu",
                    "Send To, Special Paste transforms, Compare, Quick Properties, " +
                        "Clip Order, Import/Export, Email/Gmail, QR."
                )
                parity("Search menu", "Search mode toggles exist only as simple text search on Mac.")
                parity(
                    "Description options menu",
                    "Text/RTF/HTML/image view mode, always-on-top, wrapping, " +
                        "scaling, remember position."
                )
                parity("Group menu", "New subgroup, delete group, properties; Mac currently has flat groups.")
                parity(
                    "Options pages",
                    "General, Supported Types, Keyboard Shortcuts, Copy Buffers, " +
                        "Quick Paste Keyboard, Friends, Stats, About, Advanced."
                )
                parity(
                    "Dialogs",
                    "Add Type, Copy Properties, Group Properties, Move To Group, " +
                        "Remote File, Global Clips, Delete Clip Data, Script Editor."
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    var aboutTab: some View {
        Form {
            Section("Ditto macOS") {
                LabeledContent("Version", value: "0.1.0")
                LabeledContent("Native UI", value: "SwiftUI/AppKit")
                LabeledContent("Database", value: "SQLite")
            }

            Section("Source Parity") {
                Text(
                    "The Windows codebase remains the source of truth for feature " +
                        "parity. See macos/PARITY.md for the strict backlog."
                )
                    .foregroundStyle(.secondary)
            }
        }
    }

    func missing(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.triangle")
            .foregroundStyle(.secondary)
    }

    func parity(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .fontWeight(.semibold)
            Text(detail)
                .foregroundStyle(.secondary)
        }
    }
}
