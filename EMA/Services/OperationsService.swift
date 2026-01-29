//
//  OperationsService.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Business-layer orchestration for operations (incidents/trainings/events).
/// Strict layering: Views/ViewModels call this service; this service calls OperationsRepository.
/// Does not make schema changes and does not duplicate repository responsibilities.
final class OperationsService: Sendable {

    private let repository: OperationsRepository

    init(repository: OperationsRepository = OperationsRepository()) {
        self.repository = repository
    }

    // MARK: - Read

    /// Returns all operations (admin usage).
    func fetchAll() async throws -> [Operation] {
        do {
            return try await repository.fetchAllOperations()
        } catch {
            throw mapToAppError(error)
        }
    }

    /// Returns a single operation by id.
    func fetch(by id: UUID) async throws -> Operation {
        do {
            return try await repository.fetchOperation(by: id)
        } catch {
            throw mapToAppError(error)
        }
    }

    /// Returns only operations where `is_active = true`.
    func fetchActive() async throws -> [Operation] {
        do {
            return try await repository.fetchActiveOperations()
        } catch {
            throw mapToAppError(error)
        }
    }

    /// Returns only operations where `is_visible = true`.
    func fetchVisible() async throws -> [Operation] {
        do {
            return try await repository.fetchVisibleOperations()
        } catch {
            throw mapToAppError(error)
        }
    }

    /// Returns operations where `is_active = true AND is_visible = true`.
    /// Useful for kiosk/responder lists.
    func fetchActiveVisible() async throws -> [Operation] {
        do {
            return try await repository.fetchActiveVisibleOperations()
        } catch {
            throw mapToAppError(error)
        }
    }

    // MARK: - Recurrence-Aware Operations

    /// Returns all operations that are active TODAY based on recurrence rules
    func fetchActiveTodayOperations() async throws -> [Operation] {
        let allOperations = try await repository.fetchAllOperations()
        let today = Date()

        return allOperations.filter { operation in
            operation.isActive && isOperationActiveOn(operation, date: today)
        }
    }

    /// Returns visible operations that are active TODAY based on recurrence rules
    func fetchActiveTodayVisible() async throws -> [Operation] {
        let activeTodayOps = try await fetchActiveTodayOperations()
        return activeTodayOps.filter { $0.isVisible }
    }

    /// Determines if an operation is active on a specific date based on recurrence rules
    func isOperationActiveOn(_ operation: Operation, date: Date) -> Bool {
        let calendar = Calendar.current

        switch operation.recurrenceType {
        case .oneTime:
            return isOneTimeOperationActive(operation, on: date, calendar: calendar)

        case .daily:
            return isDailyOperationActive(operation, on: date, calendar: calendar)

        case .weekly:
            return isWeeklyOperationActive(operation, on: date, calendar: calendar)

        case .monthly:
            return isMonthlyOperationActive(operation, on: date, calendar: calendar)
        }
    }

    /// Case-insensitive name search.
    func searchByName(_ query: String) async throws -> [Operation] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        do {
            return try await repository.searchOperations(byName: trimmed)
        } catch {
            throw mapToAppError(error)
        }
    }

    // MARK: - Write (Admin)

    func create(_ operation: Operation) async throws -> Operation {
        do {
            try validate(operation: operation)
            return try await repository.createOperation(operation)
        } catch {
            throw mapToAppError(error)
        }
    }

    func update(_ operation: Operation) async throws -> Operation {
        do {
            try validate(operation: operation)
            return try await repository.updateOperation(operation)
        } catch {
            throw mapToAppError(error)
        }
    }

    /// Toggle `is_active`.
    func setActive(operationId: UUID, isActive: Bool) async throws -> Operation {
        do {
            return try await repository.setOperationActive(operationId, isActive: isActive)
        } catch {
            throw mapToAppError(error)
        }
    }

    /// Toggle `is_visible`.
    func setVisible(operationId: UUID, isVisible: Bool) async throws -> Operation {
        do {
            return try await repository.setOperationVisible(operationId, isVisible: isVisible)
        } catch {
            throw mapToAppError(error)
        }
    }

    /// Deletes an operation row. (Admin-only; use with caution.)
    func delete(operationId: UUID) async throws -> Operation {
        do {
            return try await repository.deleteOperation(operationId)
        } catch {
            throw mapToAppError(error)
        }
    }

    // MARK: - Recurrence Calculation Helpers

    private func isOneTimeOperationActive(_ operation: Operation, on date: Date, calendar: Calendar) -> Bool {
        guard let startDate = operation.startDate else { return false }

        let isAfterStart = calendar.isDate(date, inSameDayAs: startDate) || date > startDate

        if let endDate = operation.endDate {
            let isBeforeEnd = calendar.isDate(date, inSameDayAs: endDate) || date < endDate
            return isAfterStart && isBeforeEnd
        }

        return isAfterStart
    }

    private func isDailyOperationActive(_ operation: Operation, on date: Date, calendar: Calendar) -> Bool {
        // Daily operations are active every day

        // Check if we've started yet
        if let startDate = operation.startDate {
            guard calendar.isDate(date, inSameDayAs: startDate) || date > startDate else {
                return false
            }
        }

        // Check if we've ended
        if let recurrenceEndDate = operation.recurrenceEndDate {
            guard calendar.isDate(date, inSameDayAs: recurrenceEndDate) || date < recurrenceEndDate else {
                return false
            }
        }

        return true
    }

    private func isWeeklyOperationActive(_ operation: Operation, on date: Date, calendar: Calendar) -> Bool {
        guard let config = operation.recurrenceConfig,
              let daysOfWeek = config.daysOfWeek,
              !daysOfWeek.isEmpty else {
            return false
        }

        // Check if we've started yet
        if let startDate = operation.startDate {
            guard calendar.isDate(date, inSameDayAs: startDate) || date > startDate else {
                return false
            }
        }

        // Check if we've ended
        if let recurrenceEndDate = operation.recurrenceEndDate {
            guard calendar.isDate(date, inSameDayAs: recurrenceEndDate) || date < recurrenceEndDate else {
                return false
            }
        }

        // Check if today matches one of the configured days
        let weekday = calendar.component(.weekday, from: date) - 1 // Convert to 0-indexed (0 = Sunday)
        return daysOfWeek.contains(weekday)
    }

    private func isMonthlyOperationActive(_ operation: Operation, on date: Date, calendar: Calendar) -> Bool {
        guard let config = operation.recurrenceConfig,
              let dayOfMonth = config.dayOfMonth else {
            return false
        }

        // Check if we've started yet
        if let startDate = operation.startDate {
            guard calendar.isDate(date, inSameDayAs: startDate) || date > startDate else {
                return false
            }
        }

        // Check if we've ended
        if let recurrenceEndDate = operation.recurrenceEndDate {
            guard calendar.isDate(date, inSameDayAs: recurrenceEndDate) || date < recurrenceEndDate else {
                return false
            }
        }

        // Check if today's day of month matches
        let todayDayOfMonth = calendar.component(.day, from: date)
        return todayDayOfMonth == dayOfMonth
    }

    // MARK: - Helpers

    private func validate(operation: Operation) throws {
        let name = operation.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            throw AppError.validation("Operation name is required.")
        }

        let category = operation.category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard category == "blue" || category == "gray" else {
            throw AppError.validation("Operation category must be blue or gray.")
        }
    }

    private func mapToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }

        if let networkError = error as? NetworkError {
            return networkError.toAppError()
        }

        if error is DecodingError {
            return .decoding("Failed to decode operations response.")
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return NetworkError.from(error).toAppError()
        }

        return .unexpected(error.localizedDescription)
    }
}
