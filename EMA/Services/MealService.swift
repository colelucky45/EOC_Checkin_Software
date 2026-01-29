//
//  MealService.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Business orchestration for meal logging.
/// Used by kiosk meal scans and admin meal reporting.
final class MealService: @unchecked Sendable {

    private let repository: MealsRepository

    init(repository: MealsRepository = MealsRepository()) {
        self.repository = repository
    }

    // MARK: - Create / Log

    /// Creates (logs) a meal entry by building a `MealLog` and inserting it.
    func createMealLog(
        id: UUID = UUID(),
        mealType: String,
        quantity: Int = 1,
        servedAt: Date = Date(),
        terminalId: String?,
        notes: String?,
        operationId: UUID?,
        userId: UUID?
    ) async throws -> MealLog {

        let normalizedMealType = mealType.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedMealType.isEmpty else {
            throw AppError.validation("Meal type is required.")
        }

        guard quantity > 0 else {
            throw AppError.validation("Meal quantity must be greater than zero.")
        }

        let mealLog = MealLog(
            id: id,
            mealType: normalizedMealType,
            quantity: quantity,
            servedAt: servedAt,
            terminalId: terminalId,
            notes: notes,
            operationId: operationId,
            userId: userId
        )

        do {
            let created = try await repository.createMealLog(mealLog)

            Logger.log(
                "Meal log created",
                level: .info,
                category: "MealService",
                metadata: [
                    "mealType": normalizedMealType,
                    "quantity": quantity,
                    "userId": userId?.uuidString ?? "n/a",
                    "operationId": operationId?.uuidString ?? "n/a",
                    "terminalId": terminalId ?? "n/a"
                ]
            )

            return created
        } catch {
            let appError = mapToAppError(error)
            Logger.log(error: appError, level: .error, category: "MealService", context: "createMealLog")
            throw appError
        }
    }

    // MARK: - Fetch

    func fetchAllMealLogs() async throws -> [MealLog] {
        do {
            return try await repository.fetchAllMealLogs()
        } catch {
            let appError = mapToAppError(error)
            Logger.log(error: appError, level: .error, category: "MealService", context: "fetchAllMealLogs")
            throw appError
        }
    }

    func fetchMealLogs(forOperation operationId: UUID) async throws -> [MealLog] {
        do {
            return try await repository.fetchMealLogs(forOperation: operationId)
        } catch {
            let appError = mapToAppError(error)
            Logger.log(error: appError, level: .error, category: "MealService", context: "fetchMealLogs(forOperation)")
            throw appError
        }
    }

    func fetchMealLogs(forUser userId: UUID) async throws -> [MealLog] {
        do {
            return try await repository.fetchMealLogs(forUser: userId)
        } catch {
            let appError = mapToAppError(error)
            Logger.log(error: appError, level: .error, category: "MealService", context: "fetchMealLogs(forUser)")
            throw appError
        }
    }

    func fetchMealLog(by id: UUID) async throws -> MealLog {
        do {
            return try await repository.fetchMealLog(by: id)
        } catch {
            let appError = mapToAppError(error)
            Logger.log(error: appError, level: .error, category: "MealService", context: "fetchMealLog(by:)")
            throw appError
        }
    }

    // MARK: - Delete (Admin)

    func deleteMealLog(_ id: UUID) async throws -> MealLog {
        do {
            let deleted = try await repository.deleteMealLog(id)

            Logger.log(
                "Meal log deleted",
                level: .warning,
                category: "MealService",
                metadata: ["mealLogId": id.uuidString]
            )

            return deleted
        } catch {
            let appError = mapToAppError(error)
            Logger.log(error: appError, level: .error, category: "MealService", context: "deleteMealLog")
            throw appError
        }
    }

    // MARK: - Helpers

    private func mapToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }

        if let networkError = error as? NetworkError {
            return networkError.toAppError()
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return NetworkError.from(error).toAppError()
        }

        return .unexpected(error.localizedDescription)
    }
}
