//
//  QrToken.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

// Represents a QR authentication token for responders.
// Mirrors the `qr_tokens` table in the database.
struct QrToken: Identifiable, Codable, Equatable, Sendable {
    
    let id: UUID
    let userId: UUID
    let token: String
    let expiresAt: Date?
    let createdAt: Date
    let operationId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case userId     = "user_id"
        case token
        case expiresAt  = "expires_at"
        case createdAt  = "created_at"
        case operationId = "operation_id"
    }
    
    /// Returns true if the QR token is expired.
    var isExpired: Bool {
        guard let expiresAt else { return false }
        return Date() >= expiresAt
    }
}
