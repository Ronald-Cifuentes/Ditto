import SwiftUI

@main
struct DittoMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow
    @StateObject private var model = ClipboardHistoryModel()

    var body: some Scene {
        WindowGroup("Ditto", id: "main") {
            ContentView()
                .environmentObject(model)
                .background(
                    MainWindowAccessor { window in
                        appDelegate.mainWindow = window
                    }
                )
                .onAppear {
                    appDelegate.model = model
                    appDelegate.openMainWindow = {
                        openWindow(id: "main")
                    }
                    model.refreshHotKeyRegistration()
                }
        }
        .commands {
            CommandMenu("Clipboard") {
                Button("Capture Now", action: model.captureNow)
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                Button("Copy Selected", action: model.copySelected)
                    .keyboardShortcut(.return, modifiers: [.command])
                Button("Copy Latest", action: model.copyLatest)
                    .keyboardShortcut("v", modifiers: [.command, .shift])
                Divider()
                Button("Delete Selected", action: model.deleteSelected)
                    .keyboardShortcut(.delete, modifiers: [])
                Button("Refresh", action: { model.refresh(status: "Refreshed") })
                    .keyboardShortcut("r", modifiers: [.command])
            }
        }

        Settings {
            SettingsView()
                .environmentObject(model)
        }
    }
}
