import AppKit
import Foundation

enum PasteboardBridge {
    static func readText() -> String? {
        NSPasteboard.general.string(forType: .string)
    }

    static func readPayload() -> ClipboardPayload? {
        let pasteboard = NSPasteboard.general

        if let urls = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL],
           !urls.isEmpty {
            let paths = urls.map(\.path).joined(separator: "\n")
            return ClipboardPayload(
                kind: .files,
                content: paths,
                payload: nil,
                metadata: "\(urls.count) file\(urls.count == 1 ? "" : "s")"
            )
        }

        if let image = NSImage(pasteboard: pasteboard),
           let tiff = image.tiffRepresentation {
            let size = image.size
            return ClipboardPayload(
                kind: .image,
                content: "Image \(Int(size.width)) x \(Int(size.height)) px",
                payload: tiff,
                metadata: "\(Int(size.width)) x \(Int(size.height)) px"
            )
        }

        if let rtf = pasteboard.data(forType: .rtf), !rtf.isEmpty {
            let content = attributedPlainText(fromRTF: rtf) ?? pasteboard.string(forType: .string) ?? "Rich text"
            return ClipboardPayload(kind: .rtf, content: content, payload: rtf, metadata: "RTF")
        }

        if let html = pasteboard.data(forType: .html), !html.isEmpty {
            let content = pasteboard.string(forType: .string)
                ?? String(data: html, encoding: .utf8)
                ?? "HTML"
            return ClipboardPayload(kind: .html, content: content, payload: html, metadata: "HTML")
        }

        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            return ClipboardPayload(kind: .text, content: text, payload: nil, metadata: "")
        }

        return nil
    }

    static func writeText(_ text: String) throws {
        try writePayload(ClipboardPayload(kind: .text, content: text, payload: nil, metadata: ""))
    }

    static func writePayload(_ payload: ClipboardPayload) throws {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch payload.kind {
        case .text:
            try writeTextPayload(payload, to: pasteboard)
        case .image:
            try writeImagePayload(payload, to: pasteboard)
        case .files:
            try writeFilePayload(payload, to: pasteboard)
        case .rtf:
            try writeDataPayload(payload, type: .rtf, missingMessage: "RTF payload is missing")
        case .html:
            try writeDataPayload(payload, type: .html, missingMessage: "HTML payload is missing")
        }
    }

    static var changeCount: Int {
        NSPasteboard.general.changeCount
    }

    private static func attributedPlainText(fromRTF data: Data) -> String? {
        guard let attributed = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        ) else {
            return nil
        }
        return attributed.string
    }

    private static func writeTextPayload(
        _ payload: ClipboardPayload,
        to pasteboard: NSPasteboard
    ) throws {
        guard pasteboard.setString(payload.content, forType: .string) else {
            throw pasteboardError("failed to write text to pasteboard")
        }
    }

    private static func writeImagePayload(
        _ payload: ClipboardPayload,
        to pasteboard: NSPasteboard
    ) throws {
        guard let data = payload.payload else {
            throw pasteboardError("image payload is missing")
        }
        pasteboard.setData(data, forType: .tiff)
        guard NSImage(data: data) != nil else {
            throw pasteboardError("image payload is not readable")
        }
    }

    private static func writeFilePayload(
        _ payload: ClipboardPayload,
        to pasteboard: NSPasteboard
    ) throws {
        let urls = payload.content
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { NSURL(fileURLWithPath: String($0)) }
        guard !urls.isEmpty, pasteboard.writeObjects(urls) else {
            throw pasteboardError("failed to write file URLs to pasteboard")
        }
    }

    private static func writeDataPayload(
        _ payload: ClipboardPayload,
        type: NSPasteboard.PasteboardType,
        missingMessage: String
    ) throws {
        guard let data = payload.payload else {
            throw pasteboardError(missingMessage)
        }
        let pasteboard = NSPasteboard.general
        pasteboard.setData(data, forType: type)
        pasteboard.setString(payload.content, forType: .string)
    }

    private static func pasteboardError(_ message: String) -> NSError {
        NSError(
            domain: "DittoMac.Pasteboard",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}
