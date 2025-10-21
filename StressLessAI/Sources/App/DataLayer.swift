import Foundation
import SQLite3

actor DataLayer {
    static let shared = DataLayer()
    private var db: OpaquePointer?

    private init() {
        let dbPath = "StressLessAI.sqlite"
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening database")
        }
        createTable()
    }

    private func createTable() {
        let createTableString = """
        CREATE TABLE IF NOT EXISTS FaceTelemetry(
            ts REAL PRIMARY KEY,
            blinkPM REAL,
            mouthOpen REAL,
            jitter REAL,
            stress REAL,
            box_x REAL,
            box_y REAL,
            box_width REAL,
            box_height REAL
        );
        """
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) != SQLITE_DONE {
                print("FaceTelemetry table could not be created.")
            }
        } else {
            print("CREATE TABLE statement could not be prepared.")
        }
        sqlite3_finalize(createTableStatement)
    }

    func insert(telemetry: FaceTelemetry) {
        let insertStatementString = "INSERT INTO FaceTelemetry (ts, blinkPM, mouthOpen, jitter, stress, box_x, box_y, box_width, box_height) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);"
        var insertStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_double(insertStatement, 1, telemetry.ts)
            sqlite3_bind_double(insertStatement, 2, telemetry.blinkPM)
            sqlite3_bind_double(insertStatement, 3, telemetry.mouthOpen)
            sqlite3_bind_double(insertStatement, 4, telemetry.jitter)
            sqlite3_bind_double(insertStatement, 5, telemetry.stress)
            sqlite3_bind_double(insertStatement, 6, telemetry.box.origin.x)
            sqlite3_bind_double(insertStatement, 7, telemetry.box.origin.y)
            sqlite3_bind_double(insertStatement, 8, telemetry.box.width)
            sqlite3_bind_double(insertStatement, 9, telemetry.box.height)

            if sqlite3_step(insertStatement) != SQLITE_DONE {
                print("Could not insert row.")
            }
        } else {
            print("INSERT statement could not be prepared.")
        }
        sqlite3_finalize(insertStatement)
    }
}
