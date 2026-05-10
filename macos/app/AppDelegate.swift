import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var model: ClipboardHistoryModel?
    weak var mainWindow: NSWindow?
    var openMainWindow: (() -> Void)?

    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        GlobalHotKeyController.shared.action = { [weak self] in
            self?.showMainWindow()
        }
        configureStatusItem()

        if CommandLine.arguments.contains("--quit-after-launch") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                NSApp.terminate(nil)
            }
        }
    }

    @objc func showMainWindow() {
        let existingWindow = mainWindow
            ?? NSApp.windows.first { $0.identifier?.rawValue == "DittoMainWindow" }
            ?? NSApp.windows.first { $0.title == "Ditto" }

        if let window = existingWindow {
            show(window)
            return
        }

        openMainWindow?()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            if let window = self?.mainWindow
                ?? NSApp.windows.first(where: { $0.identifier?.rawValue == "DittoMainWindow" })
                ?? NSApp.windows.first(where: { $0.title == "Ditto" }) {
                self?.show(window)
            } else {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    private func show(_ window: NSWindow) {
        NSApp.activate(ignoringOtherApps: true)
        window.deminiaturize(nil)
        window.makeKeyAndOrderFront(nil)
    }

    @objc func captureNow() {
        Task { @MainActor in
            model?.captureNow()
        }
    }

    @objc func copyLatest() {
        Task { @MainActor in
            model?.copyLatest()
        }
    }

    @objc func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(
            systemSymbolName: "doc.on.clipboard",
            accessibilityDescription: "Ditto"
        )
        item.button?.imagePosition = .imageOnly

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Ditto", action: #selector(showMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Capture Now", action: #selector(captureNow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Copy Latest", action: #selector(copyLatest), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit Ditto",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        item.menu = menu

        statusItem = item
    }
}
