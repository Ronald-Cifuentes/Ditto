import Foundation
import SQLite3

enum ClipKind: String {
    case text
    case image
    case files
    case rtf
    case html

    var label: String {
        switch self {
        case .text:
            return "Text"
        case .image:
            return "Image"
        case .files:
            return "Files"
        case .rtf:
            return "RTF"
        case .html:
            return "HTML"
        }
    }

    var symbolName: String {
        switch self {
        case .text:
            return "text.alignleft"
        case .image:
            return "photo"
        case .files:
            return "folder"
        case .rtf:
            return "doc.richtext"
        case .html:
            return "chevron.left.forwardslash.chevron.right"
        }
    }
}

struct ClipboardPayload: Hashable {
    let kind: ClipKind
    let content: String
    let payload: Data?
    let metadata: String
}

struct ClipItem: Identifiable, Hashable {
    let id: Int64
    let createdAt: String
    let kind: ClipKind
    let content: String
    let payload: Data?
    let metadata: String
    let groupName: String
    let isFavorite: Bool

    var preview: String {
        if content.isEmpty {
            return kind.label
        }
        return PreviewText.make(from: content, maxLength: 140)
    }

    var filePaths: [String] {
        guard kind == .files else {
            return []
        }
        return content
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
    }
}

enum DittoMacPaths {
    static func configuredDatabasePath() throws -> String {
        if let configured = ProcessInfo.processInfo.environment["DITTO_MAC_DB"], !configured.isEmpty {
            return configured
        }

        let home = FileManager.default.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("DittoMac")
            .appendingPathComponent("history.sqlite")
            .path
    }
}

enum PreviewText {
    static func make(from text: String, maxLength: Int) -> String {
        var result = ""
        result.reserveCapacity(min(text.count, maxLength))

        for scalar in text.unicodeScalars {
            switch scalar {
            case "\n":
                result += "\\n"
            case "\r":
                result += "\\r"
            case "\t":
                result += "\\t"
            case "\0":
                result += "\\0"
            default:
                result.unicodeScalars.append(scalar)
            }

            if result.count > maxLength {
                return String(result.prefix(max(0, maxLength - 3))) + "..."
            }
        }

        return result
    }
}

final class SQLiteHistoryStore {
    let path: String
    private var database: OpaquePointer?

    init(path: String) throws {
        self.path = path
        try open()
        try initializeSchema()
    }

    deinit {
        if database != nil {
            sqlite3_close(database)
        }
    }

    func addClip(_ content: String) throws -> Bool {
        try addRecord(ClipboardPayload(kind: .text, content: content, payload: nil, metadata: ""))
    }

    func addRecord(_ record: ClipboardPayload) throws -> Bool {
        let hasPayload = !(record.payload?.isEmpty ?? true)
        guard !record.content.isEmpty || hasPayload else {
            return false
        }

        let hash = hashRecord(record)
        if let latest = try latestHashKindAndContent(),
           latest.hash == hash,
           latest.kind == record.kind.rawValue,
           latest.content == record.content {
            return false
        }

        let statement = try Statement(
            database: database,
            sql: "INSERT INTO clips(content, content_hash, kind, payload, metadata, group_name, is_favorite) VALUES (?, ?, ?, ?, ?, 'History', 0)"
        )
        defer { statement.finalize() }

        try bindText(record.content, to: statement.pointer, index: 1)
        try bindText(hash, to: statement.pointer, index: 2)
        try bindText(record.kind.rawValue, to: statement.pointer, index: 3)
        try bindBlob(record.payload, to: statement.pointer, index: 4)
        try bindText(record.metadata, to: statement.pointer, index: 5)

        guard sqlite3_step(statement.pointer) == SQLITE_DONE else {
            throw sqliteError("insert clip")
        }
        return true
    }

    func list(limit: Int) throws -> [ClipItem] {
        let safeLimit = max(1, min(limit, 1000))
        let statement = try Statement(
            database: database,
            sql: "SELECT id, created_at, content, kind, payload, metadata, group_name, is_favorite FROM clips ORDER BY id DESC LIMIT ?"
        )
        defer { statement.finalize() }

        guard sqlite3_bind_int(statement.pointer, 1, Int32(safeLimit)) == SQLITE_OK else {
            throw sqliteError("bind limit")
        }

        var clips: [ClipItem] = []
        while true {
            let step = sqlite3_step(statement.pointer)
            if step == SQLITE_DONE {
                return clips
            }
            guard step == SQLITE_ROW else {
                throw sqliteError("list clips")
            }

            clips.append(ClipItem(
                id: sqlite3_column_int64(statement.pointer, 0),
                createdAt: columnText(statement.pointer, 1),
                kind: ClipKind(rawValue: columnText(statement.pointer, 3)) ?? .text,
                content: columnText(statement.pointer, 2),
                payload: columnBlob(statement.pointer, 4),
                metadata: columnText(statement.pointer, 5),
                groupName: columnText(statement.pointer, 6),
                isFavorite: sqlite3_column_int(statement.pointer, 7) != 0
            ))
        }
    }

    func get(id: Int64) throws -> ClipItem? {
        let statement = try Statement(
            database: database,
            sql: "SELECT id, created_at, content, kind, payload, metadata, group_name, is_favorite FROM clips WHERE id = ?"
        )
        defer { statement.finalize() }

        guard sqlite3_bind_int64(statement.pointer, 1, id) == SQLITE_OK else {
            throw sqliteError("bind clip id")
        }

        let step = sqlite3_step(statement.pointer)
        if step == SQLITE_DONE {
            return nil
        }
        guard step == SQLITE_ROW else {
            throw sqliteError("read clip")
        }

        return ClipItem(
            id: sqlite3_column_int64(statement.pointer, 0),
            createdAt: columnText(statement.pointer, 1),
            kind: ClipKind(rawValue: columnText(statement.pointer, 3)) ?? .text,
            content: columnText(statement.pointer, 2),
            payload: columnBlob(statement.pointer, 4),
            metadata: columnText(statement.pointer, 5),
            groupName: columnText(statement.pointer, 6),
            isFavorite: sqlite3_column_int(statement.pointer, 7) != 0
        )
    }

    func latest() throws -> ClipItem? {
        return try list(limit: 1).first
    }

    func count() throws -> Int {
        let statement = try Statement(database: database, sql: "SELECT COUNT(*) FROM clips")
        defer { statement.finalize() }

        guard sqlite3_step(statement.pointer) == SQLITE_ROW else {
            throw sqliteError("count clips")
        }
        return Int(sqlite3_column_int(statement.pointer, 0))
    }

    func delete(id: Int64) throws {
        let statement = try Statement(database: database, sql: "DELETE FROM clips WHERE id = ?")
        defer { statement.finalize() }

        guard sqlite3_bind_int64(statement.pointer, 1, id) == SQLITE_OK else {
            throw sqliteError("bind clip id")
        }
        guard sqlite3_step(statement.pointer) == SQLITE_DONE else {
            throw sqliteError("delete clip")
        }
    }

    func setFavorite(id: Int64, isFavorite: Bool) throws {
        let statement = try Statement(database: database, sql: "UPDATE clips SET is_favorite = ? WHERE id = ?")
        defer { statement.finalize() }

        guard sqlite3_bind_int(statement.pointer, 1, isFavorite ? 1 : 0) == SQLITE_OK else {
            throw sqliteError("bind favorite")
        }
        guard sqlite3_bind_int64(statement.pointer, 2, id) == SQLITE_OK else {
            throw sqliteError("bind clip id")
        }
        guard sqlite3_step(statement.pointer) == SQLITE_DONE else {
            throw sqliteError("set favorite")
        }
    }

    func moveClip(id: Int64, toGroup groupName: String) throws {
        let normalized = normalizeGroupName(groupName)
        let statement = try Statement(database: database, sql: "UPDATE clips SET group_name = ? WHERE id = ?")
        defer { statement.finalize() }

        try bindText(normalized, to: statement.pointer, index: 1)
        guard sqlite3_bind_int64(statement.pointer, 2, id) == SQLITE_OK else {
            throw sqliteError("bind clip id")
        }
        guard sqlite3_step(statement.pointer) == SQLITE_DONE else {
            throw sqliteError("move clip")
        }
    }

    func groups() throws -> [String] {
        let statement = try Statement(database: database, sql: "SELECT DISTINCT group_name FROM clips ORDER BY group_name COLLATE NOCASE")
        defer { statement.finalize() }

        var names = ["History"]
        while true {
            let step = sqlite3_step(statement.pointer)
            if step == SQLITE_DONE {
                return Array(Set(names)).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            }
            guard step == SQLITE_ROW else {
                throw sqliteError("list groups")
            }
            let name = normalizeGroupName(columnText(statement.pointer, 0))
            if !names.contains(name) {
                names.append(name)
            }
        }
    }

    func clear() throws {
        try execute("DELETE FROM clips")
    }

    private func open() throws {
        let databaseURL = URL(fileURLWithPath: path)
        let directory = databaseURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        if sqlite3_open_v2(path, &handle, flags, nil) != SQLITE_OK {
            let message = handle.flatMap { sqlite3_errmsg($0) }.map { String(cString: $0) } ?? "unknown sqlite error"
            if handle != nil {
                sqlite3_close(handle)
            }
            throw NSError(domain: "DittoMac.SQLite", code: 1, userInfo: [NSLocalizedDescriptionKey: "open database: \(message)"])
        }
        database = handle
    }

    private func initializeSchema() throws {
        try execute("PRAGMA journal_mode=WAL")
        try execute("""
            CREATE TABLE IF NOT EXISTS clips (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
                content TEXT NOT NULL,
                content_hash TEXT NOT NULL,
                kind TEXT NOT NULL DEFAULT 'text',
                payload BLOB,
                metadata TEXT NOT NULL DEFAULT '',
                group_name TEXT NOT NULL DEFAULT 'History',
                is_favorite INTEGER NOT NULL DEFAULT 0
            )
            """)
        try addColumnIfMissing(name: "kind", definition: "TEXT NOT NULL DEFAULT 'text'")
        try addColumnIfMissing(name: "payload", definition: "BLOB")
        try addColumnIfMissing(name: "metadata", definition: "TEXT NOT NULL DEFAULT ''")
        try addColumnIfMissing(name: "group_name", definition: "TEXT NOT NULL DEFAULT 'History'")
        try addColumnIfMissing(name: "is_favorite", definition: "INTEGER NOT NULL DEFAULT 0")
        try execute("CREATE INDEX IF NOT EXISTS idx_clips_created ON clips(id DESC)")
        try execute("CREATE INDEX IF NOT EXISTS idx_clips_kind ON clips(kind)")
        try execute("CREATE INDEX IF NOT EXISTS idx_clips_group_name ON clips(group_name COLLATE NOCASE)")
        try execute("CREATE INDEX IF NOT EXISTS idx_clips_favorite ON clips(is_favorite)")
    }

    private func execute(_ sql: String) throws {
        var error: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(database, sql, nil, nil, &error) != SQLITE_OK {
            let message = error.map { String(cString: $0) } ?? "unknown sqlite error"
            sqlite3_free(error)
            throw NSError(domain: "DittoMac.SQLite", code: 2, userInfo: [NSLocalizedDescriptionKey: "execute sql: \(message)"])
        }
    }

    private func addColumnIfMissing(name: String, definition: String) throws {
        guard try !columnExists(name: name) else {
            return
        }
        try execute("ALTER TABLE clips ADD COLUMN \(name) \(definition)")
    }

    private func columnExists(name: String) throws -> Bool {
        let statement = try Statement(database: database, sql: "PRAGMA table_info(clips)")
        defer { statement.finalize() }

        while true {
            let step = sqlite3_step(statement.pointer)
            if step == SQLITE_DONE {
                return false
            }
            guard step == SQLITE_ROW else {
                throw sqliteError("read table info")
            }
            if columnText(statement.pointer, 1) == name {
                return true
            }
        }
    }

    private func latestHashKindAndContent() throws -> (hash: String, kind: String, content: String)? {
        let statement = try Statement(
            database: database,
            sql: "SELECT content_hash, kind, content FROM clips ORDER BY id DESC LIMIT 1"
        )
        defer { statement.finalize() }

        let step = sqlite3_step(statement.pointer)
        if step == SQLITE_DONE {
            return nil
        }
        guard step == SQLITE_ROW else {
            throw sqliteError("read latest clip")
        }
        return (columnText(statement.pointer, 0), columnText(statement.pointer, 1), columnText(statement.pointer, 2))
    }

    private func bindText(_ text: String, to statement: OpaquePointer?, index: Int32) throws {
        let bytes = Array(text.utf8)
        guard bytes.count <= Int(Int32.max) else {
            throw NSError(domain: "DittoMac.SQLite", code: 3, userInfo: [NSLocalizedDescriptionKey: "text is too large for sqlite binding"])
        }

        let result = bytes.withUnsafeBufferPointer { buffer in
            sqlite3_bind_text(statement, index, buffer.baseAddress, Int32(bytes.count), sqliteTransient)
        }
        guard result == SQLITE_OK else {
            throw sqliteError("bind text")
        }
    }

    private func bindBlob(_ data: Data?, to statement: OpaquePointer?, index: Int32) throws {
        guard let data else {
            guard sqlite3_bind_null(statement, index) == SQLITE_OK else {
                throw sqliteError("bind null blob")
            }
            return
        }

        guard data.count <= Int(Int32.max) else {
            throw NSError(domain: "DittoMac.SQLite", code: 6, userInfo: [NSLocalizedDescriptionKey: "payload is too large for sqlite binding"])
        }

        let result = data.withUnsafeBytes { buffer in
            sqlite3_bind_blob(statement, index, buffer.baseAddress, Int32(data.count), sqliteTransient)
        }
        guard result == SQLITE_OK else {
            throw sqliteError("bind blob")
        }
    }

    private func columnText(_ statement: OpaquePointer?, _ column: Int32) -> String {
        guard let raw = sqlite3_column_text(statement, column) else {
            return ""
        }

        let byteCount = Int(sqlite3_column_bytes(statement, column))
        let data = Data(bytes: raw, count: byteCount)
        return String(data: data, encoding: .utf8) ?? ""
    }

    private func columnBlob(_ statement: OpaquePointer?, _ column: Int32) -> Data? {
        guard sqlite3_column_type(statement, column) != SQLITE_NULL else {
            return nil
        }
        guard let raw = sqlite3_column_blob(statement, column) else {
            return Data()
        }

        let byteCount = Int(sqlite3_column_bytes(statement, column))
        return Data(bytes: raw, count: byteCount)
    }

    private func sqliteError(_ action: String) -> NSError {
        let message = database.flatMap { sqlite3_errmsg($0) }.map { String(cString: $0) } ?? "unknown sqlite error"
        return NSError(domain: "DittoMac.SQLite", code: 4, userInfo: [NSLocalizedDescriptionKey: "\(action): \(message)"])
    }

    private func hashRecord(_ record: ClipboardPayload) -> String {
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

    private func hashBytes(_ bytes: [UInt8]) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in bytes {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return String(format: "%016llx", hash)
    }

    private func normalizeGroupName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "History" : trimmed
    }
}

private final class Statement {
    let pointer: OpaquePointer?

    init(database: OpaquePointer?, sql: String) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            let message = database.flatMap { sqlite3_errmsg($0) }.map { String(cString: $0) } ?? "unknown sqlite error"
            throw NSError(domain: "DittoMac.SQLite", code: 5, userInfo: [NSLocalizedDescriptionKey: "prepare statement: \(message)"])
        }
        pointer = statement
    }

    func finalize() {
        sqlite3_finalize(pointer)
    }
}

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
