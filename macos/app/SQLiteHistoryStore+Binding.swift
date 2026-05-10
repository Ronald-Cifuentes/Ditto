import Foundation
import SQLite3

extension SQLiteHistoryStore {
    func bindText(_ text: String, to statement: OpaquePointer?, index: Int32) throws {
        let bytes = Array(text.utf8)
        guard bytes.count <= Int(Int32.max) else {
            throw NSError(
                domain: "DittoMac.SQLite",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "text is too large for sqlite binding"]
            )
        }

        let result = bytes.withUnsafeBufferPointer { buffer in
            sqlite3_bind_text(statement, index, buffer.baseAddress, Int32(bytes.count), sqliteTransient)
        }
        guard result == SQLITE_OK else {
            throw sqliteError("bind text")
        }
    }

    func bindBlob(_ data: Data?, to statement: OpaquePointer?, index: Int32) throws {
        guard let data else {
            guard sqlite3_bind_null(statement, index) == SQLITE_OK else {
                throw sqliteError("bind null blob")
            }
            return
        }

        guard data.count <= Int(Int32.max) else {
            throw NSError(
                domain: "DittoMac.SQLite",
                code: 6,
                userInfo: [NSLocalizedDescriptionKey: "payload is too large for sqlite binding"]
            )
        }

        let result = data.withUnsafeBytes { buffer in
            sqlite3_bind_blob(statement, index, buffer.baseAddress, Int32(data.count), sqliteTransient)
        }
        guard result == SQLITE_OK else {
            throw sqliteError("bind blob")
        }
    }

    func columnText(_ statement: OpaquePointer?, _ column: Int32) -> String {
        guard let raw = sqlite3_column_text(statement, column) else {
            return ""
        }

        let byteCount = Int(sqlite3_column_bytes(statement, column))
        let data = Data(bytes: raw, count: byteCount)
        return String(data: data, encoding: .utf8) ?? ""
    }

    func columnBlob(_ statement: OpaquePointer?, _ column: Int32) -> Data? {
        guard sqlite3_column_type(statement, column) != SQLITE_NULL else {
            return nil
        }
        guard let raw = sqlite3_column_blob(statement, column) else {
            return Data()
        }

        let byteCount = Int(sqlite3_column_bytes(statement, column))
        return Data(bytes: raw, count: byteCount)
    }

    func sqliteError(_ action: String) -> NSError {
        let message = database
            .flatMap { sqlite3_errmsg($0) }
            .map { String(cString: $0) }
            ?? "unknown sqlite error"
        return NSError(
            domain: "DittoMac.SQLite",
            code: 4,
            userInfo: [NSLocalizedDescriptionKey: "\(action): \(message)"]
        )
    }

    func hashRecord(_ record: ClipboardPayload) -> String {
        var bytes = Array(record.kind.rawValue.utf8)
        bytes.append(0)
        bytes.append(contentsOf: record.content.utf8)
        bytes.append(0)
        bytes.append(contentsOf: record.metadata.utf8)
        bytes.append(0)
        if let payload = record.payload {
            bytes.append(contentsOf: payload)
        }
        return hashBytes(bytes)
    }

    func hashBytes(_ bytes: [UInt8]) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in bytes {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return String(format: "%016llx", hash)
    }

    func normalizeGroupName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "History" : trimmed
    }
}
