import Foundation
import SQLite3

final class Statement {
    let pointer: OpaquePointer?

    init(database: OpaquePointer?, sql: String) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            let message = database
                .flatMap { sqlite3_errmsg($0) }
                .map { String(cString: $0) }
                ?? "unknown sqlite error"
            throw NSError(
                domain: "DittoMac.SQLite",
                code: 5,
                userInfo: [NSLocalizedDescriptionKey: "prepare statement: \(message)"]
            )
        }
        pointer = statement
    }

    func finalize() {
        sqlite3_finalize(pointer)
    }
}

let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
