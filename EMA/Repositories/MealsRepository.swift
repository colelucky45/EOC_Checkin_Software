//
//  MealsRepository.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Handles all database operations for meal logging.
final class MealsRepository: Sendable {

    private let database: DatabaseProviderProtocol
    private let table = "meals_log"

    init(database: DatabaseProviderProtocol = BackendFactory.current.database) {
        self.database = database
    }

    // MARK: - Fetch All

    func fetchAllMealLogs() async throws -> [MealLog] {
        try await database.fetchMany(
            from: table,
            filters: [],
            order: .desc("served_at"),
            limit: nil
        )
    }

    // MARK: - Fetch by Operation

    func fetchMealLogs(forOperation operationId: UUID) async throws -> [MealLog] {
        try await database.fetchMany(
            from: table,
            filters: [.equals("operation_id", operationId.uuidString)],
            order: .desc("served_at"),
            limit: nil
        )
    }

    // MARK: - Fetch by User

    func fetchMealLogs(forUser userId: UUID) async throws -> [MealLog] {
        try await database.fetchMany(
            from: table,
            filters: [.equals("user_id", userId.uuidString)],
            order: .desc("served_at"),
            limit: nil
        )
    }

    // MARK: - Fetch Single

    func fetchMealLog(by id: UUID) async throws -> MealLog {
        try await database.fetchOne(from: table, id: id)
    }

    // MARK: - Create

    func createMealLog(_ mealLog: MealLog) async throws -> MealLog {
        try await database.insert(mealLog, into: table)
    }

    // MARK: - Delete (Admin Only)

    func deleteMealLog(_ id: UUID) async throws -> MealLog {
        try await database.delete(from: table, id: id)
    }
}
