//
//  LocalSyncEvent.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Local/offline representation of a system sync log event.
/// Used by SyncEngine to track last-known sync status.
struct LocalSyncEvent: Identifiable, Codable, Equatable, Sendable {
    
    let id: UUID
    let syncTime: Date
    let status: String
    let details: String?
    
    /// Local timestamp indicating when this record was saved to the device.
    let locallyRecordedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case syncTime        = "sync_time"
        case status
        case details
        case locallyRecordedAt = "locally_recorded_at"
    }
}

extension LocalSyncEvent {
    
    /// Create a local sync record from an API event.
    init(from api: SystemSyncEvent, locallyRecordedAt: Date = Date()) {
        self.id = api.id
        self.syncTime = api.syncTime
        self.status = api.status
        self.details = api.details
        self.locallyRecordedAt = locallyRecordedAt
    }
    
    /// Converts back to API model if needed.
    func toAPIModel() -> SystemSyncEvent {
        SystemSyncEvent(
            id: id,
            syncTime: syncTime,
            status: status,
            details: details
        )
    }
}
