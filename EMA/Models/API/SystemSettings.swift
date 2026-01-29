//
//  SystemSettings.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Represents global system mode configuration (blue vs gray sky).
/// Mirrors the `system_settings` table in the database.
struct SystemSettings: Identifiable, Codable, Equatable, Sendable {
    
    let id: UUID
    let mode: String          // "blue" or "gray"
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case mode
        case updatedAt = "updated_at"
    }
    
    var isBlueSky: Bool {
        mode == "blue"
    }
    
    var isGraySky: Bool {
        mode == "gray"
    }
}


