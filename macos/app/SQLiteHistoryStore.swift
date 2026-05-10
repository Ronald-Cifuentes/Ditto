import Foundation
import SQLite3

final class SQLiteHistoryStore {
    let path: String
    var database: OpaquePointer?

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
}

extension SQLiteHistoryStore {
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
            sql: """
                INSERT INTO clips(
                    content, content_hash, kind, payload, metadata, group_name, is_favorite
                )
                VALUES (?, ?, ?, ?, ?, 'History', 0)
                """
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
            sql: """
                SELECT id, created_at, content, kind, payload, metadata, group_name, is_favorite
                FROM clips
                ORDER BY id DESC
                LIMIT ?
                """
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
            sql: """
                SELECT id, created_at, content, kind, payload, metadata, group_name, is_favorite
                FROM clips
                WHERE id = ?
                """
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
        let statement = try Statement(
            database: database,
            sql: """
                SELECT DISTINCT group_name
                FROM clips
                ORDER BY group_name COLLATE NOCASE
                """
        )
        defer { statement.finalize() }

        var names = ["History"]
        while true {
            let step = sqlite3_step(statement.pointer)
            if step == SQLITE_DONE {
                return Array(Set(names)).sorted {
                    $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
                }
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
}
