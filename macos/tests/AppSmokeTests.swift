import AppKit
import Foundation

@main
struct AppSmokeTests {
    static func main() throws {
        let path = try DittoMacPaths.configuredDatabasePath()
        try? FileManager.default.removeItem(atPath: path)

        let store = try SQLiteHistoryStore(path: path)
        try store.clear()
        assertEqual(0, try store.count(), "initial count")

        let first = "first graphical clip\nline two"
        let second = "second graphical clip"
        let nul = "nul\0inside"
        let htmlData = Data("<strong>html clip</strong>".utf8)
        let imageData = try makeImageData()
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ditto-mac-file-\(UUID().uuidString).txt")
        try "file clip".write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        assertTrue(try store.addClip(first), "insert first")
        assertFalse(try store.addClip(first), "duplicate suppression")
        assertTrue(try store.addClip(nul), "insert nul-containing text")
        assertTrue(try store.addRecord(ClipboardPayload(kind: .image, content: "Image 2 x 2 px", payload: imageData, metadata: "2 x 2 px")), "insert image")
        assertTrue(try store.addRecord(ClipboardPayload(kind: .files, content: fileURL.path, payload: nil, metadata: "1 file")), "insert file")
        assertTrue(try store.addRecord(ClipboardPayload(kind: .html, content: "html clip", payload: htmlData, metadata: "HTML")), "insert html")
        assertTrue(try store.addClip(second), "insert second")
        assertEqual(6, try store.count(), "count after inserts")

        let latest = try unwrap(try store.latest(), "latest clip")
        assertEqual(second, latest.content, "latest content")
        try store.setFavorite(id: latest.id, isFavorite: true)
        try store.moveClip(id: latest.id, toGroup: "Work")

        let movedLatest = try unwrap(try store.get(id: latest.id), "moved latest")
        assertEqual(true, movedLatest.isFavorite, "favorite persisted")
        assertEqual("Work", movedLatest.groupName, "group persisted")
        assertTrue(try store.groups().contains("Work"), "group listed")

        let clips = try store.list(limit: 2)
        assertEqual(2, clips.count, "limited list")
        assertEqual(second, clips[0].content, "newest first")

        let imageClip = try unwrap(try store.list(limit: 10).first { $0.kind == .image }, "image clip")
        assertEqual(imageData, imageClip.payload, "image payload preserved")

        let fileClip = try unwrap(try store.list(limit: 10).first { $0.kind == .files }, "file clip")
        assertEqual(fileURL.path, fileClip.content, "file path preserved")

        let nulClip = try unwrap(try store.list(limit: 10).first { $0.content == nul }, "nul clip")
        let fetched = try unwrap(try store.get(id: nulClip.id), "fetch by id")
        assertEqual(nul, fetched.content, "fetch preserves embedded nul")

        try store.delete(id: imageClip.id)
        assertEqual(5, try store.count(), "delete selected")

        let pasteboardText = "Ditto graphical pasteboard smoke \(Date().timeIntervalSince1970)"
        try PasteboardBridge.writeText(pasteboardText)
        assertEqual(pasteboardText, PasteboardBridge.readText(), "pasteboard round trip")

        try PasteboardBridge.writePayload(ClipboardPayload(kind: .files, content: fileURL.path, payload: nil, metadata: "1 file"))
        let filePayload = try unwrap(PasteboardBridge.readPayload(), "file payload")
        assertEqual(ClipKind.files, filePayload.kind, "file pasteboard kind")
        assertEqual(fileURL.path, filePayload.content, "file pasteboard content")

        try PasteboardBridge.writePayload(ClipboardPayload(kind: .image, content: "Image 2 x 2 px", payload: imageData, metadata: "2 x 2 px"))
        let imagePayload = try unwrap(PasteboardBridge.readPayload(), "image payload")
        assertEqual(ClipKind.image, imagePayload.kind, "image pasteboard kind")

        try store.clear()
        assertEqual(0, try store.count(), "clear")

        print("ditto-mac app smoke passed")
    }

    private static func unwrap<T>(_ value: T?, _ label: String) throws -> T {
        guard let value else {
            throw NSError(domain: "DittoMac.AppSmoke", code: 1, userInfo: [NSLocalizedDescriptionKey: "\(label) was nil"])
        }
        return value
    }

    private static func assertTrue(_ condition: Bool, _ label: String) {
        if !condition {
            fatalError("FAIL: \(label)")
        }
    }

    private static func assertFalse(_ condition: Bool, _ label: String) {
        if condition {
            fatalError("FAIL: \(label)")
        }
    }

    private static func assertEqual<T: Equatable>(_ expected: T, _ actual: T, _ label: String) {
        if expected != actual {
            fatalError("FAIL: \(label): expected \(expected), got \(actual)")
        }
    }

    private static func makeImageData() throws -> Data {
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 2,
            pixelsHigh: 2,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw NSError(domain: "DittoMac.AppSmoke", code: 2, userInfo: [NSLocalizedDescriptionKey: "could not create image rep"])
        }

        rep.setColor(NSColor(calibratedRed: 1, green: 0, blue: 0, alpha: 1), atX: 0, y: 0)
        rep.setColor(NSColor(calibratedRed: 0, green: 1, blue: 0, alpha: 1), atX: 1, y: 0)
        rep.setColor(NSColor(calibratedRed: 0, green: 0, blue: 1, alpha: 1), atX: 0, y: 1)
        rep.setColor(NSColor(calibratedRed: 1, green: 1, blue: 0, alpha: 1), atX: 1, y: 1)

        guard let data = rep.representation(using: .tiff, properties: [:]) else {
            throw NSError(domain: "DittoMac.AppSmoke", code: 3, userInfo: [NSLocalizedDescriptionKey: "could not encode image rep"])
        }
        return data
    }
}
