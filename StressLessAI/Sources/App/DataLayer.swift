import Foundation
import SQLite3

actor DataLayer {
    static let shared = DataLayer()
    private var db: OpaquePointer?

    private init() {
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Unable to determine Application Support directory.")
        }

        let dbDirURL = appSupportURL.appendingPathComponent("StressLessAI", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dbDirURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            fatalError("Unable to create database directory: \(error.localizedDescription)")
        }

        let dbPathURL = dbDirURL.appendingPathComponent("StressLessAI.sqlite")

        if sqlite3_open(dbPathURL.path, &db) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            fatalError("Error opening database: \(errmsg)")
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
        if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error preparing create table statement: \(errmsg)")
            sqlite3_finalize(createTableStatement)
            return
        }

        if sqlite3_step(createTableStatement) != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error creating FaceTelemetry table: \(errmsg)")
        }
        sqlite3_finalize(createTableStatement)
    }

    func insert(telemetry: FaceTelemetry) {
        let insertStatementString = "INSERT INTO FaceTelemetry (ts, blinkPM, mouthOpen, jitter, stress, box_x, box_y, box_width, box_height) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);"
        var insertStatement: OpaquePointer?

        if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Error preparing insert statement: \(errmsg)")
            sqlite3_finalize(insertStatement)
            return
        }

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
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("Could not insert row: \(errmsg)")
        }
        sqlite3_finalize(insertStatement)
    }

    func fetchRecentTelemetry(limit: Int) -> [FaceTelemetry] {
        let queryStatementString = "SELECT * FROM FaceTelemetry ORDER BY ts DESC LIMIT ?;"
        var queryStatement: OpaquePointer?
        var telemetryData: [FaceTelemetry] = []

        if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(queryStatement, 1, Int32(limit))
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let ts = sqlite3_column_double(queryStatement, 0)
                let blinkPM = sqlite3_column_double(queryStatement, 1)
                let mouthOpen = sqlite3_column_double(queryStatement, 2)
                let jitter = sqlite3_column_double(queryStatement, 3)
                let stress = sqlite3_column_double(queryStatement, 4)
                let box_x = sqlite3_column_double(queryStatement, 5)
                let box_y = sqlite3_column_double(queryStatement, 6)
                let box_width = sqlite3_column_double(queryStatement, 7)
                let box_height = sqlite3_column_double(queryStatement, 8)

                let box = CGRect(x: box_x, y: box_y, width: box_width, height: box_height)
                let telemetry = FaceTelemetry(ts: ts, blinkPM: blinkPM, mouthOpen: mouthOpen, jitter: jitter, stress: stress, box: box)
                telemetryData.append(telemetry)
            }
        } else {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            print("SELECT statement could not be prepared: \(errmsg)")
        }
        sqlite3_finalize(queryStatement)
        return telemetryData
    }
}
