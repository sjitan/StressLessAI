import Foundation
import SQLite3

// MARK: - Data Models
struct Session {
    let id: Int64
    let startTime: Date
    var endTime: Date?
    var recommendation: String?
}

struct Telemetry {
    let sessionId: Int64
    let timestamp: Date
    let blinkPM: Double
    let mouthOpen: Double
    let jitter: Double
    let frown: Double
    let stress: Double
}

struct Baseline {
    let id: String // e.g., "shortTermEMA", "longTermEMA"
    var value: Double
    let lastUpdated: Date
}


// MARK: - DataLayer Actor
actor DataLayer {
    static let shared = DataLayer()
    private var db: OpaquePointer?
    private var currentSessionId: Int64?

    private init() {
        guard let dbPathURL = Self.getDatabasePath() else {
            Logger.log("Failed to get database path.", level: .error)
            fatalError("Failed to get database path.")
        }

        if sqlite3_open(dbPathURL.path, &db) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db)!)
            Logger.log("Error opening database: \(errmsg)", level: .error)
            fatalError("Error opening database: \(errmsg)")
        }

        Logger.log("Database opened successfully at \(dbPathURL.path)")
        createSchema()
    }

    private static func getDatabasePath() -> URL? {
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dbDirURL = appSupportURL.appendingPathComponent("StressLessAI", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dbDirURL, withIntermediateDirectories: true, attributes: nil)
            return dbDirURL.appendingPathComponent("StressLessAI-v2.sqlite")
        } catch {
            Logger.log("Unable to create database directory: \(error.localizedDescription)", level: .error)
            return nil
        }
    }

    // MARK: - Schema Creation
    private func createSchema() {
        executeNonQuery("""
        CREATE TABLE IF NOT EXISTS Session (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            startTime REAL NOT NULL,
            endTime REAL,
            recommendation TEXT
        );
        """)

        executeNonQuery("""
        CREATE TABLE IF NOT EXISTS Telemetry (
            sessionId INTEGER NOT NULL,
            timestamp REAL NOT NULL,
            blinkPM REAL NOT NULL,
            mouthOpen REAL NOT NULL,
            jitter REAL NOT NULL,
            frown REAL NOT NULL,
            stress REAL NOT NULL,
            FOREIGN KEY(sessionId) REFERENCES Session(id)
        );
        """)

        executeNonQuery("""
        CREATE TABLE IF NOT EXISTS Baseline (
            id TEXT PRIMARY KEY,
            value REAL NOT NULL,
            lastUpdated REAL NOT NULL
        );
        """)
        Logger.log("Database schema verified.")
    }

    // MARK: - Session Management
    func startNewSession() -> Int64 {
        let startTime = Date().timeIntervalSince1970
        let sql = "INSERT INTO Session (startTime) VALUES (?);"

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logError("Failed to prepare session insert statement")
            return -1
        }

        sqlite3_bind_double(stmt, 1, startTime)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            logError("Failed to execute session insert")
            sqlite3_finalize(stmt)
            return -1
        }

        let newSessionId = sqlite3_last_insert_rowid(db)
        self.currentSessionId = newSessionId
        sqlite3_finalize(stmt)

        Logger.log("Started new session with ID: \(newSessionId)")
        return newSessionId
    }

    func endSession(id: Int64, recommendation: String) {
        let endTime = Date().timeIntervalSince1970
        let sql = "UPDATE Session SET endTime = ?, recommendation = ? WHERE id = ?;"

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logError("Failed to prepare session update statement")
            return
        }

        sqlite3_bind_double(stmt, 1, endTime)
        sqlite3_bind_text(stmt, 2, (recommendation as NSString).utf8String, -1, nil)
        sqlite3_bind_int64(stmt, 3, id)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            logError("Failed to execute session update")
            sqlite3_finalize(stmt)
            return
        }

        sqlite3_finalize(stmt)
        Logger.log("Ended session with ID: \(id)")
        self.currentSessionId = nil
    }

    // MARK: - Telemetry Logging
    func insertTelemetry(_ telemetry: Telemetry) {
        guard let sessionId = self.currentSessionId else {
            Logger.log("Attempted to insert telemetry without an active session.", level: .warning)
            return
        }

        let sql = "INSERT INTO Telemetry (sessionId, timestamp, blinkPM, mouthOpen, jitter, frown, stress) VALUES (?, ?, ?, ?, ?, ?, ?);"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logError("Failed to prepare telemetry insert statement")
            return
        }

        sqlite3_bind_int64(stmt, 1, sessionId)
        sqlite3_bind_double(stmt, 2, telemetry.timestamp.timeIntervalSince1970)
        sqlite3_bind_double(stmt, 3, telemetry.blinkPM)
        sqlite3_bind_double(stmt, 4, telemetry.mouthOpen)
        sqlite3_bind_double(stmt, 5, telemetry.jitter)
        sqlite3_bind_double(stmt, 6, telemetry.frown)
        sqlite3_bind_double(stmt, 7, telemetry.stress)

        if sqlite3_step(stmt) != SQLITE_DONE {
            logError("Failed to execute telemetry insert")
        }

        sqlite3_finalize(stmt)
    }

    // MARK: - Baseline Persistence
    func saveBaseline(id: String, value: Double) {
        let now = Date().timeIntervalSince1970
        let sql = "INSERT OR REPLACE INTO Baseline (id, value, lastUpdated) VALUES (?, ?, ?);"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logError("Failed to prepare baseline save statement")
            return
        }

        sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
        sqlite3_bind_double(stmt, 2, value)
        sqlite3_bind_double(stmt, 3, now)

        if sqlite3_step(stmt) != SQLITE_DONE {
            logError("Failed to save baseline for \(id)")
        }
        sqlite3_finalize(stmt)
    }

    func loadBaseline(id: String) -> Baseline? {
        let sql = "SELECT value, lastUpdated FROM Baseline WHERE id = ?;"
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logError("Failed to prepare baseline load statement")
            return nil
        }

        sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)

        if sqlite3_step(stmt) == SQLITE_ROW {
            let value = sqlite3_column_double(stmt, 0)
            let lastUpdated = sqlite3_column_double(stmt, 1)
            sqlite3_finalize(stmt)
            return Baseline(id: id, value: value, lastUpdated: Date(timeIntervalSince1970: lastUpdated))
        }

        sqlite3_finalize(stmt)
        return nil // Not found
    }

    // MARK: - Reporting Queries
    func fetchAllSessions() -> [Session] {
        let sql = "SELECT id, startTime, endTime, recommendation FROM Session ORDER BY startTime DESC;"
        var stmt: OpaquePointer?
        var sessions: [Session] = []

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logError("Failed to prepare fetch all sessions statement")
            return []
        }

        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let startTime = sqlite3_column_double(stmt, 1)
            let endTime = sqlite3_column_double(stmt, 2)
            let recommendation = String(cString: sqlite3_column_text(stmt, 3))

            sessions.append(Session(
                id: id,
                startTime: Date(timeIntervalSince1970: startTime),
                endTime: Date(timeIntervalSince1970: endTime),
                recommendation: recommendation
            ))
        }

        sqlite3_finalize(stmt)
        return sessions
    }

    func fetchTelemetry(for sessionId: Int64) -> [Telemetry] {
        let sql = "SELECT timestamp, blinkPM, mouthOpen, jitter, frown, stress FROM Telemetry WHERE sessionId = ? ORDER BY timestamp ASC;"
        var stmt: OpaquePointer?
        var telemetryData: [Telemetry] = []

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            logError("Failed to prepare fetch telemetry statement")
            return []
        }

        sqlite3_bind_int64(stmt, 1, sessionId)

        while sqlite3_step(stmt) == SQLITE_ROW {
            let timestamp = sqlite3_column_double(stmt, 0)
            let blinkPM = sqlite3_column_double(stmt, 1)
            let mouthOpen = sqlite3_column_double(stmt, 2)
            let jitter = sqlite3_column_double(stmt, 3)
            let frown = sqlite3_column_double(stmt, 4)
            let stress = sqlite3_column_double(stmt, 5)

            telemetryData.append(Telemetry(
                sessionId: sessionId,
                timestamp: Date(timeIntervalSince1970: timestamp),
                blinkPM: blinkPM,
                mouthOpen: mouthOpen,
                jitter: jitter,
                frown: frown,
                stress: stress
            ))
        }

        sqlite3_finalize(stmt)
        return telemetryData
    }


    // MARK: - Helper Methods
    private func executeNonQuery(_ sql: String) {
        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            logError("Failed to execute non-query statement: \(sql)")
        }
    }

    private func logError(_ message: String) {
        let errmsg = String(cString: sqlite3_errmsg(db)!)
        Logger.log("\(message): \(errmsg)", level: .error)
    }
}
