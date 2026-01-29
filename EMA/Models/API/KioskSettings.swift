//
//  KioskSettings.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

// Represents configuration settings for a kiosk terminal/user.
// Mirrors the `kiosk_settings` table in the database.
struct KioskSettings: Identifiable, Codable, Equatable, Sendable {

    let id: UUID
    let terminalId: String
    let kioskUserId: UUID
    let kioskMode: String          // "check_in", "check_out", or "meal"
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case terminalId  = "terminal_id"
        case kioskUserId = "kiosk_user_id"
        case kioskMode   = "kiosk_mode"
        case updatedAt   = "updated_at"
    }
    
    // Returns true if this kiosk is configured for meal logging.
    var isMealMode: Bool {
        kioskMode == "meal"
    }
    
    // Returns true if this kiosk is for check-ins only.
    var isCheckInMode: Bool {
        kioskMode == "check_in"
    }
    
    // Returns true if this kiosk is for check-outs only.
    var isCheckOutMode: Bool {
        kioskMode == "check_out"
    }
}
