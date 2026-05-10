import AppKit
import Foundation
import SwiftUI

@MainActor
final class ClipboardHistoryModel: ObservableObject {
    @Published private(set) var clips: [ClipItem] = []
    @Published var selectedID: Int64?
    @Published var searchText = "" {
        didSet {
            applyFilter()
        }
    }
    @Published private(set) var filteredClips: [ClipItem] = []
    @Published private(set) var statusText = "Ready"
    @Published private(set) var databasePath = ""
    @Published private(set) var groups: [String] = ["All", "Favorites", "History"]
    @Published var selectedGroup = "All" {
        didSet {
            applyFilter()
        }
    }
    @Published var newGroupName = ""
    @Published var isMonitoring = true {
        didSet {
            configureTimer()
        }
    }
    @Published var isGlobalHotKeyEnabled = UserDefaults.standard.object(
        forKey: "DittoMacGlobalHotKeyEnabled"
    ) as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(isGlobalHotKeyEnabled, forKey: "DittoMacGlobalHotKeyEnabled")
            configureHotKey()
        }
    }

    private var store: SQLiteHistoryStore?
    private var timer: Timer?
    private var lastPasteboardChangeCount = PasteboardBridge.changeCount

    init() {
        do {
            let path = try DittoMacPaths.configuredDatabasePath()
            databasePath = path
            store = try SQLiteHistoryStore(path: path)
            refresh(status: "Ready")
            configureTimer()
            configureHotKey()
        } catch {
            statusText = error.localizedDescription
        }
    }
}

extension ClipboardHistoryModel {
    var selectedClip: ClipItem? {
        guard let selectedID else {
            return filteredClips.first
        }
        return clips.first { $0.id == selectedID }
    }

    func refresh(status: String? = nil) {
        guard let store else {
            return
        }

        do {
            clips = try store.list(limit: 500)
            let storedGroups = try store.groups()
            groups = ["All", "Favorites"] + storedGroups
            if !groups.contains(selectedGroup) {
                selectedGroup = "All"
            }
            applyFilter()
            if selectedID == nil || !clips.contains(where: { $0.id == selectedID }) {
                selectedID = filteredClips.first?.id
            }
            if let status {
                statusText = status
            }
        } catch {
            statusText = error.localizedDescription
        }
    }

    func captureNow() {
        guard let store else {
            return
        }
        guard let payload = PasteboardBridge.readPayload() else {
            statusText = "No supported pasteboard item"
            return
        }

        do {
            let inserted = try store.addRecord(payload)
            let status = inserted
                ? "Captured \(payload.kind.label.lowercased()) from pasteboard"
                : "Pasteboard already captured"
            refresh(status: status)
        } catch {
            statusText = error.localizedDescription
        }
    }

    func copySelected() {
        do {
            try copySelectedToPasteboard()
        } catch {
            statusText = error.localizedDescription
        }
    }

    func pasteSelected() {
        do {
            try PasteExecutor.pasteIntoFrontmostApp {
                try copySelectedToPasteboard()
            }
            statusText = "Pasted selected clip"
        } catch {
            statusText = error.localizedDescription
        }
    }

    func copyLatest() {
        guard let store else {
            return
        }

        do {
            guard let latest = try store.latest() else {
                statusText = "No clips saved"
                return
            }
            try PasteboardBridge.writePayload(ClipboardPayload(
                kind: latest.kind,
                content: latest.content,
                payload: latest.payload,
                metadata: latest.metadata
            ))
            selectedID = latest.id
            statusText = "Copied latest clip"
        } catch {
            statusText = error.localizedDescription
        }
    }

    func deleteSelected() {
        guard let store, let selectedID else {
            statusText = "No clip selected"
            return
        }

        do {
            try store.delete(id: selectedID)
            self.selectedID = nil
            refresh(status: "Deleted clip \(selectedID)")
        } catch {
            statusText = error.localizedDescription
        }
    }

    func toggleFavoriteSelected() {
        guard let store, let clip = selectedClip else {
            statusText = "No clip selected"
            return
        }

        do {
            try store.setFavorite(id: clip.id, isFavorite: !clip.isFavorite)
            refresh(status: clip.isFavorite ? "Removed favorite" : "Marked favorite")
        } catch {
            statusText = error.localizedDescription
        }
    }

    func moveSelectedToGroup(_ groupName: String) {
        guard let store, let selectedID else {
            statusText = "No clip selected"
            return
        }

        do {
            try store.moveClip(id: selectedID, toGroup: groupName)
            let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
            selectedGroup = trimmedName.isEmpty ? "History" : groupName
            refresh(status: "Moved clip to \(selectedGroup)")
        } catch {
            statusText = error.localizedDescription
        }
    }

    func createGroupAndMoveSelected() {
        let name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            statusText = "Enter a group name"
            return
        }

        moveSelectedToGroup(name)
        newGroupName = ""
    }

    func clearHistory() {
        guard let store else {
            return
        }

        do {
            try store.clear()
            selectedID = nil
            refresh(status: "Cleared history")
        } catch {
            statusText = error.localizedDescription
        }
    }

    func revealDatabase() {
        guard !databasePath.isEmpty else {
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: databasePath)])
    }

    func refreshHotKeyRegistration() {
        configureHotKey()
    }
}

private extension ClipboardHistoryModel {
    func copySelectedToPasteboard() throws {
        guard let selectedClip else {
            throw NSError(
                domain: "DittoMac.Selection",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No clip selected"]
            )
        }

        try PasteboardBridge.writePayload(ClipboardPayload(
            kind: selectedClip.kind,
            content: selectedClip.content,
            payload: selectedClip.payload,
            metadata: selectedClip.metadata
        ))
        statusText = "Copied clip \(selectedClip.id)"
    }

    func applyFilter() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        var scoped = clips
        if selectedGroup == "Favorites" {
            scoped = scoped.filter(\.isFavorite)
        } else if selectedGroup != "All" {
            scoped = scoped.filter { $0.groupName == selectedGroup }
        }

        if query.isEmpty {
            filteredClips = scoped
        } else {
            filteredClips = scoped.filter { clip in
                clip.content.localizedCaseInsensitiveContains(query)
                    || clip.kind.label.localizedCaseInsensitiveContains(query)
                    || clip.metadata.localizedCaseInsensitiveContains(query)
                    || clip.groupName.localizedCaseInsensitiveContains(query)
                    || clip.createdAt.localizedCaseInsensitiveContains(query)
                    || String(clip.id).contains(query)
            }
        }

        if let selectedID,
           !filteredClips.contains(where: { $0.id == selectedID }) {
            self.selectedID = filteredClips.first?.id
        }
    }

    func configureTimer() {
        timer?.invalidate()
        timer = nil

        guard isMonitoring else {
            statusText = "Monitoring paused"
            return
        }

        lastPasteboardChangeCount = PasteboardBridge.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollPasteboard()
            }
        }
        statusText = "Monitoring pasteboard"
    }

    func pollPasteboard() {
        let currentChangeCount = PasteboardBridge.changeCount
        guard currentChangeCount != lastPasteboardChangeCount else {
            return
        }

        lastPasteboardChangeCount = currentChangeCount
        captureNow()
    }

    func configureHotKey() {
        do {
            if isGlobalHotKeyEnabled {
                try GlobalHotKeyController.shared.register()
                statusText = "Global hotkey enabled: Command-Option-V"
            } else {
                GlobalHotKeyController.shared.unregister()
                statusText = "Global hotkey disabled"
            }
        } catch {
            statusText = "Global hotkey unavailable: \(error.localizedDescription)"
        }
    }
}
