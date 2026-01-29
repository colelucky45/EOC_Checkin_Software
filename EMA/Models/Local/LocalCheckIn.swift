//
//  LocalCheckIn.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Local/offline representation of a check-in record.
/// Stored for sync operations and offline kiosk mode support.
struct LocalCheckIn: Identifiable, Codable, Equatable, Sendable {
    
    let id: UUID
    let userId: UUID
    let operationId: UUID
    let checkinTime: Date
    let checkoutTime: Date?
    let terminalId: String?
    let notes: String?
    let overnight: Bool?  // Made optional to match API model
    let roleOnCheckin: String?
    let checkoutNote: String?
    
    /// Indicates whether this record has been synced with the server.
    /// `nil` means the sync state is unknown.
    let syncedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId         = "user_id"
        case operationId    = "operation_id"
        case checkinTime    = "checkin_time"
        case checkoutTime   = "checkout_time"
        case terminalId     = "terminal_id"
        case notes
        case overnight
        case roleOnCheckin  = "role_on_checkin"
        case checkoutNote   = "checkout_note"
        case syncedAt       = "synced_at"
    }
}

extension LocalCheckIn {
    /// Initialize a LocalCheckIn from an API CheckIn.
    init(from api: CheckIn, syncedAt: Date? = Date()) {
        self.id = api.id
        self.userId = api.userId
        self.operationId = api.operationId
        self.checkinTime = api.checkinTime
        self.checkoutTime = api.checkoutTime
        self.terminalId = api.terminalId
        self.notes = api.notes
        self.overnight = api.overnight
        self.roleOnCheckin = api.roleOnCheckin
        self.checkoutNote = api.checkoutNote
        self.syncedAt = syncedAt
    }
    
    /// Converts back to API model (used when pushing to server).
    func toAPIModel() -> CheckIn {
        CheckIn(
            id: id,
            userId: userId,
            operationId: operationId,
            checkinTime: checkinTime,
            checkoutTime: checkoutTime,
            terminalId: terminalId,
            notes: notes,
            overnight: overnight,
            roleOnCheckin: roleOnCheckin,
            checkoutNote: checkoutNote
        )
    }
}
