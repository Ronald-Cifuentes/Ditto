import AppKit
import CoreGraphics
import Foundation

enum PasteExecutor {
    static func pasteIntoFrontmostApp(afterCopy copy: () throws -> Void) throws {
        let previousApp = NSWorkspace.shared.frontmostApplication
        try copy()

        if let previousApp, previousApp.bundleIdentifier != Bundle.main.bundleIdentifier {
            previousApp.activate()
        } else {
            NSApp.hide(nil)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            sendCommandV()
        }
    }

    private static func sendCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
