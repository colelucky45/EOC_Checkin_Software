//
//  KioskStatus.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

// Tracks live heartbeat status for kiosk terminals.
// Mirrors the `kiosk_status` table in the database.
struct KioskStatus: Codable, Equatable, Sendable {
    
    let terminalId: String
    let lastHeartbeat: Date
    
    enum CodingKeys: String, CodingKey {
        case terminalId   = "terminal_id"
        case lastHeartbeat = "last_heartbeat"
    }
    
    // Returns true if the kiosk has not checked in recently.
    func isStale(timeout: TimeInterval = 60) -> Bool {
        Date().timeIntervalSince(lastHeartbeat) > timeout
    }
}
