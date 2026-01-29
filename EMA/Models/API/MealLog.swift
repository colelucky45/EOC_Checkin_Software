//
//  MealLog.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

// Represents a logged meal service event (Breakfast, Lunch, Dinner).
// Mirrors the `meals_log` table in the database.
struct MealLog: Identifiable, Codable, Equatable, Sendable {
    
    // MARK: - Schema-Aligned Fields
    let id: UUID
    let mealType: String          // "Breakfast", "Lunch", or "Dinner"
    let quantity: Int
    let servedAt: Date
    let terminalId: String?
    let notes: String?
    let operationId: UUID?
    let userId: UUID?
    
    // MARK: - Computed Helpers
    
    // Whether this meal entry is associated with a specific user.
    var hasUser: Bool {
        userId != nil
    }
    
    // Whether this meal entry is associated with an active operation.
    var hasOperation: Bool {
        operationId != nil
    }
    
    // Provides a user-friendly summary of the meal.
    var mealSummary: String {
        "\(mealType) × \(quantity)"
    }
    
    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case mealType     = "meal_type"
        case quantity
        case servedAt     = "served_at"
        case terminalId   = "terminal_id"
        case notes
        case operationId  = "operation_id"
        case userId       = "user_id"
    }
}
