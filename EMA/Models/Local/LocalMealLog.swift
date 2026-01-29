//
//  LocalMealLog.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Local/offline representation of a meal log entry.
/// Used by offline kiosk mode and queued sync operations.
struct LocalMealLog: Identifiable, Codable, Equatable, Sendable {
    
    let id: UUID
    let mealType: String
    let quantity: Int
    let servedAt: Date
    let terminalId: String?
    let notes: String?
    let operationId: UUID?
    let userId: UUID?
    
    /// Timestamp of last successful sync with server.
    let syncedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case mealType     = "meal_type"
        case quantity
        case servedAt     = "served_at"
        case terminalId   = "terminal_id"
        case notes
        case operationId  = "operation_id"
        case userId       = "user_id"
        case syncedAt     = "synced_at"
    }
}

extension LocalMealLog {
    
    /// Create a local record from the API model.
    init(from api: MealLog, syncedAt: Date? = Date()) {
        self.id = api.id
        self.mealType = api.mealType
        self.quantity = api.quantity
        self.servedAt = api.servedAt
        self.terminalId = api.terminalId
        self.notes = api.notes
        self.operationId = api.operationId
        self.userId = api.userId
        self.syncedAt = syncedAt
    }
    
    /// Converts back to API model for push-sync.
    func toAPIModel() -> MealLog {
        MealLog(
            id: id,
            mealType: mealType,
            quantity: quantity,
            servedAt: servedAt,
            terminalId: terminalId,
            notes: notes,
            operationId: operationId,
            userId: userId
        )
    }
}
