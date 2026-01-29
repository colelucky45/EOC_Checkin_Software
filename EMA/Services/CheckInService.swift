//
//  CheckInService.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Business orchestration for check-in / check-out workflows.
/// - Strict layering: ViewModels call this service; this service calls repositories.
/// - No schema changes; uses existing repositories/models only.
final class CheckInService: @unchecked Sendable {

    private let checkInRepository: CheckInRepository
    private let operationsRepository: OperationsRepository
    private let usersRepository: UsersRepository

    init(
        checkInRepository: CheckInRepository = CheckInRepository(),
        operationsRepository: OperationsRepository = OperationsRepository(),
        usersRepository: UsersRepository = UsersRepository()
    ) {
        self.checkInRepository = checkInRepository
        self.operationsRepository = operationsRepository
        self.usersRepository = usersRepository
    }

    // MARK: - Check In

    /// Creates a new check-in record for a user on an operation.
    ///
    /// Validations:
    /// - Ensures the user exists and is active
    /// - Ensures the operation exists (fetch by id)
    /// - Ensures the user exists (fetch by id)
    /// - Prevents double check-in if an active check-in exists
    func checkInUser(
        userId: UUID,
        operationId: UUID,
        terminalId: String?,
        roleOnCheckin: String?,
        notes: String?,
        overnight: Bool = false
    ) async throws -> CheckIn {
        do {
            // Existence checks (do not assume model fields)
            let operation = try await operationsRepository.fetchOperation(by: operationId)
            let user = try await usersRepository.fetchUser(by: userId)

            guard user.isActive else {
                throw AppError.validation("User is inactive.")
            }

            guard operation.isActive, operation.isVisible else {
                throw AppError.validation("Operation is not active.")
            }

            // Check if user is already checked into THIS specific operation
            let openCheckIns = try await checkInRepository.fetchOpenCheckIns(for: userId)
            if let existingCheckIn = openCheckIns.first(where: { $0.operationId == operationId }) {
                throw AppError.conflict("You're already checked into this operation.")
            }

            // Allow check-in to a different operation even if checked in elsewhere
            // (This supports multi-operation attendance)

            let created = try await checkInRepository.checkIn(
                userId: userId,
                operationId: operationId,
                terminalId: terminalId,
                roleOnCheckin: roleOnCheckin,
                notes: notes,
                overnight: overnight
            )

            Logger.log(
                "Check-in created",
                level: .info,
                category: "CheckInService",
                metadata: [
                    "userId": userId.uuidString,
                    "operationId": operationId.uuidString,
                    "terminalId": terminalId ?? "n/a",
                    "overnight": overnight
                ]
            )

            Haptics.success()
            return created
        } catch {
            let appError = mapToAppError(error)
            Logger.log(error: appError, level: .error, category: "CheckInService", context: "checkInUser")
            Haptics.error()
            throw appError
        }
    }

    /// Checks in a user against the single active, visible operation in a category.
    func checkInUserForCategory(
        userId: UUID,
        category: String,
        terminalId: String?,
        roleOnCheckin: String?,
        notes: String?,
        overnight: Bool = false
    ) async throws -> CheckIn {
        do {
            let user = try await usersRepository.fetchUser(by: userId)
            guard user.isActive else {
                throw AppError.validation("User is inactive.")
            }

            // Fetch active operations for this category
            let normalizedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let operations = try await operationsRepository.fetchActiveVisibleOperations()
            let matching = operations.filter {
                $0.category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedCategory
            }

            guard !matching.isEmpty else {
                throw AppError.validation("No active operation available.")
            }
            guard matching.count == 1, let operation = matching.first else {
                throw AppError.conflict("Multiple active operations are available.")
            }

            // Check if user is already checked into THIS specific operation
            let openCheckIns = try await checkInRepository.fetchOpenCheckIns(for: userId)
            if let existingCheckIn = openCheckIns.first(where: { $0.operationId == operation.id }) {
                throw AppError.conflict("You're already checked into this operation.")
            }

            // Allow check-in to a different operation even if checked in elsewhere
            // (This supports multi-operation attendance)

            let created = try await checkInRepository.checkIn(
                userId: userId,
                operationId: operation.id,
                terminalId: terminalId,
                roleOnCheckin: roleOnCheckin,
                notes: notes,
                overnight: overnight
            )

            Logger.log(
                "Check-in created",
                level: .info,
                category: "CheckInService",
                metadata: [
                    "userId": userId.uuidString,
                    "operationId": operation.id.uuidString,
                    "terminalId": terminalId ?? "n/a",
                    "overnight": overnight
                ]
            )

            Haptics.success()
            return created
        } catch {
            let appError = mapToAppError(error)
            Logger.log(error: appError, level: .error, category: "CheckInService", context: "checkInUserForCategory")
            Haptics.error()
            throw appError
        }
    }

    // MARK: - Check Out

    /// Checks out an existing check-in record by id.
    ///
    /// Note: this does not try to infer the "current" check-in because that would
    /// require assumptions about the CheckIn model field names. Callers can:
    /// - fetchCurrentCheckIn(for:) then pass the record id here.
    func checkOut(
        checkInId: UUID,
        checkoutNote: String?
    ) async throws -> CheckIn {
        do {
            let updated = try await checkInRepository.checkOut(
                checkInId: checkInId,
                checkoutNote: checkoutNote
            )

            Logger.log(
                "Check-out recorded",
                level: .info,
                category: "CheckInService",
                metadata: [
                    "checkInId": checkInId.uuidString
                ]
            )

            Haptics.success()
            return updated
        } catch {
            let appError = mapToAppError(error)
            Logger.log(error: appError, level: .error, category: "CheckInService", context: "checkOut")
            Haptics.error()
            throw appError
        }
    }

    /// Checks out the current open check-in for a user.
    func checkOutUser(
        userId: UUID,
        checkoutNote: String?,
        allowIfOperationInvalid: Bool
    ) async throws -> CheckIn {
        do {
            let openCheckIns = try await checkInRepository.fetchOpenCheckIns(for: userId)
            guard let current = openCheckIns.first else {
                throw AppError.conflict("User is not currently checked in.")
            }

            if openCheckIns.count > 1 {
                throw AppError.conflict("Multiple active check-ins detected.")
            }

            let operation = try await operationsRepository.fetchOperation(by: current.operationId)
            if !(operation.isActive && operation.isVisible) && !allowIfOperationInvalid {
                throw AppError.validation("Operation is no longer active.")
            }

            let updated = try await checkInRepository.checkOut(
                checkInId: current.id,
                checkoutNote: checkoutNote
            )

            Logger.log(
                "Check-out recorded",
                level: .info,
                category: "CheckInService",
                metadata: [
                    "checkInId": current.id.uuidString
                ]
            )

            Haptics.success()
            return updated
        } catch {
            let appError = mapToAppError(error)
            Logger.log(error: appError, level: .error, category: "CheckInService", context: "checkOutUser")
            Haptics.error()
            throw appError
        }
    }

    // MARK: - Queries

    func fetchActiveCheckIns(operationId: UUID) async throws -> [CheckIn] {
        do {
            let items = try await checkInRepository.fetchActiveCheckIns(operationId: operationId)
            return items
        } catch {
            let appError = mapToAppError(error)
            Logger.log(error: appError, level: .error, category: "CheckInService", context: "fetchActiveCheckIns")
            throw appError
        }
    }

    func fetchAllCheckIns() async throws -> [CheckIn] {
        do {
            return try await checkInRepository.fetchAllCheckIns()
        } catch {
            let appError = mapToAppError(error)
            Logger.log(error: appError, level: .error, category: "CheckInService", context: "fetchAllCheckIns")
            throw appError
        }
    }

    func fetchOpenCheckIns() async throws -> [CheckIn] {
        do {
            return try await checkInRepository.fetchOpenCheckIns()
        } catch {
            let appError = mapToAppError(error)
            Logger.log(error: appError, level: .error, category: "CheckInService", context: "fetchOpenCheckIns")
            throw appError
        }
    }

    func fetchUserHistory(userId: UUID) async throws -> [CheckIn] {
        do {
            let items = try await checkInRepository.fetchCheckIns(for: userId)
            return items
        } catch {
            let appError = mapToAppError(error)
            Logger.log(error: appError, level: .error, category: "CheckInService", context: "fetchUserHistory")
            throw appError
        }
    }

    /// Returns the active check-in for a user (if any).
    func fetchCurrentCheckIn(userId: UUID) async throws -> CheckIn? {
        do {
            return try await checkInRepository.fetchCurrentCheckIn(for: userId)
        } catch {
            let appError = mapToAppError(error)
            Logger.log(error: appError, level: .error, category: "CheckInService", context: "fetchCurrentCheckIn")
            throw appError
        }
    }

    // MARK: - Helpers

    private func mapToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }

        if let networkError = error as? NetworkError {
            return networkError.toAppError()
        }

        // Best-effort classification without assuming vendor error types.
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return NetworkError.from(error).toAppError()
        }

        return .unexpected(error.localizedDescription)
    }
}
