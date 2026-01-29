//
//  SystemSyncEvent.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Represents a sync operation logged by the backend.
/// Mirrors the `system_sync_log` table in the database.
struct SystemSyncEvent: Identifiable, Codable, Equatable, Sendable {
    
    let id: UUID
    let syncTime: Date
    let status: String
    let details: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case syncTime = "sync_time"
        case status
        case details
    }
    
    /// Returns true if the sync event indicates failure.
    var isFailure: Bool {
        status.lowercased() == "failed" || status.lowercased() == "error"
    }
    
    /// Returns true if the sync event was successful.
    var isSuccess: Bool {
        status.lowercased() == "success"
    }
}
