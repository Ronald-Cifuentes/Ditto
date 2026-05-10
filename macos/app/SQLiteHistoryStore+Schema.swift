import Foundation
import SQLite3

struct LatestClipSignature {
    let hash: String
    let kind: String
    let content: String
}

extension SQLiteHistoryStore {
    func open() throws {
        let databaseURL = URL(fileURLWithPath: path)
        let directory = databaseURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        if sqlite3_open_v2(path, &handle, flags, nil) != SQLITE_OK {
            let message = handle
                .flatMap { sqlite3_errmsg($0) }
                .map { String(cString: $0) }
                ?? "unknown sqlite error"
            if handle != nil {
                sqlite3_close(handle)
            }
            throw NSError(
                domain: "DittoMac.SQLite",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "open database: \(message)"]
            )
        }
        database = handle
    }

    func initializeSchema() throws {
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
        try execute("""
            CREATE INDEX IF NOT EXISTS idx_clips_group_name
            ON clips(group_name COLLATE NOCASE)
            """)
        try execute("CREATE INDEX IF NOT EXISTS idx_clips_favorite ON clips(is_favorite)")
    }

    func execute(_ sql: String) throws {
        var error: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(database, sql, nil, nil, &error) != SQLITE_OK {
            let message = error.map { String(cString: $0) } ?? "unknown sqlite error"
            sqlite3_free(error)
            throw NSError(
                domain: "DittoMac.SQLite",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "execute sql: \(message)"]
            )
        }
    }

    func addColumnIfMissing(name: String, definition: String) throws {
        guard try !columnExists(name: name) else {
            return
        }
        try execute("ALTER TABLE clips ADD COLUMN \(name) \(definition)")
    }

    func columnExists(name: String) throws -> Bool {
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

    func latestHashKindAndContent() throws -> LatestClipSignature? {
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
        return LatestClipSignature(
            hash: columnText(statement.pointer, 0),
            kind: columnText(statement.pointer, 1),
            content: columnText(statement.pointer, 2)
        )
    }
}
