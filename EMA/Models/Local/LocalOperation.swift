//
//  LocalOperation.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Local/offline representation of an operation (blue/gray event).
/// Supports offline mode, caching, and sync reconciliation.
struct LocalOperation: Identifiable, Codable, Equatable, Sendable {
    
    let id: UUID
    let category: String
    let name: String
    let description: String?
    let isActive: Bool
    let createdAt: Date
    let startDate: Date?
    let endDate: Date?
    let startTime: String?
    let endTime: String?
    let isVisible: Bool
    
    /// Tracks last successful sync time.
    let syncedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case category
        case name
        case description
        case isActive     = "is_active"
        case createdAt    = "created_at"
        case startDate    = "start_date"
        case endDate      = "end_date"
        case startTime    = "start_time"
        case endTime      = "end_time"
        case isVisible    = "is_visible"
        case syncedAt     = "synced_at"
    }
}

extension LocalOperation {
    
    /// Creates a local representation of an API Operation.
    init(from api: Operation, syncedAt: Date? = Date()) {
        self.id = api.id
        self.category = api.category
        self.name = api.name
        self.description = api.description
        self.isActive = api.isActive
        self.createdAt = api.createdAt
        self.startDate = api.startDate
        self.endDate = api.endDate
        self.startTime = api.startTime
        self.endTime = api.endTime
        self.isVisible = api.isVisible
        self.syncedAt = syncedAt
    }
    
    /// Converts back to the API model for up-sync.
    func toAPIModel() -> Operation {
        Operation(
            id: id,
            category: category,
            name: name,
            description: description,
            isActive: isActive,
            createdAt: createdAt,
            startDate: startDate,
            endDate: endDate,
            startTime: startTime,
            endTime: endTime,
            isVisible: isVisible
        )
    }
}


