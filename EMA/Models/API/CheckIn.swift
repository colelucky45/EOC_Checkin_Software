//
//  CheckIn.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Represents a responder check-in/out event.
/// Mirrors the `checkin_log` table in the database.
struct CheckIn: Identifiable, Equatable, Sendable {

    // MARK: - Schema-Aligned Fields
    let id: UUID
    let userId: UUID
    let operationId: UUID
    let checkinTime: Date
    let checkoutTime: Date?
    let terminalId: String?
    let notes: String?
    let overnight: Bool?  // Made optional to handle potential NULL from database
    let roleOnCheckin: String?
    let checkoutNote: String?

    // MARK: - Memberwise Initializer
    init(
        id: UUID,
        userId: UUID,
        operationId: UUID,
        checkinTime: Date,
        checkoutTime: Date? = nil,
        terminalId: String? = nil,
        notes: String? = nil,
        overnight: Bool? = false,
        roleOnCheckin: String? = nil,
        checkoutNote: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.operationId = operationId
        self.checkinTime = checkinTime
        self.checkoutTime = checkoutTime
        self.terminalId = terminalId
        self.notes = notes
        self.overnight = overnight
        self.roleOnCheckin = roleOnCheckin
        self.checkoutNote = checkoutNote
    }

    // MARK: - Computed Properties
    
    /// Returns true if the record does NOT have a checkout time yet.
    var isCurrentlyCheckedIn: Bool {
        checkoutTime == nil
    }
    
    /// Human-friendly duration of check-in.
    var duration: TimeInterval? {
        guard let checkoutTime else { return nil }
        return checkoutTime.timeIntervalSince(checkinTime)
    }
    
    /// Formats duration as "2h 14m" etc.
    var formattedDuration: String? {
        guard let seconds = duration else { return nil }
        
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case userId        = "user_id"
        case operationId   = "operation_id"
        case checkinTime   = "checkin_time"
        case checkoutTime  = "checkout_time"
        case terminalId    = "terminal_id"
        case notes
        case overnight
        case roleOnCheckin = "role_on_checkin"
        case checkoutNote  = "checkout_note"
    }

    // MARK: - Custom Decoding (handles potential timestamp format variations)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        operationId = try container.decode(UUID.self, forKey: .operationId)
        checkinTime = try container.decode(Date.self, forKey: .checkinTime)
        checkoutTime = try container.decodeIfPresent(Date.self, forKey: .checkoutTime)
        terminalId = try container.decodeIfPresent(String.self, forKey: .terminalId)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        overnight = try container.decodeIfPresent(Bool.self, forKey: .overnight)
        roleOnCheckin = try container.decodeIfPresent(String.self, forKey: .roleOnCheckin)
        checkoutNote = try container.decodeIfPresent(String.self, forKey: .checkoutNote)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(operationId, forKey: .operationId)
        try container.encode(checkinTime, forKey: .checkinTime)
        try container.encodeIfPresent(checkoutTime, forKey: .checkoutTime)
        try container.encodeIfPresent(terminalId, forKey: .terminalId)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(overnight, forKey: .overnight)
        try container.encodeIfPresent(roleOnCheckin, forKey: .roleOnCheckin)
        try container.encodeIfPresent(checkoutNote, forKey: .checkoutNote)
    }
}

// MARK: - Codable Conformance
extension CheckIn: Codable {}
