//
//  DuplicateOperationViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class DuplicateOperationViewModel: ObservableObject {

    // MARK: - Published Form State

    @Published var name: String
    @Published var category: String
    @Published var description: String
    @Published var isActive: Bool
    @Published var isVisible: Bool
    @Published var startDateEnabled: Bool
    @Published var endDateEnabled: Bool
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var startTime: String
    @Published var endTime: String

    // MARK: - Recurrence Fields

    @Published var recurrenceType: RecurrenceType
    @Published var isPerpetual: Bool
    @Published var recurrenceEndDate: Date

    // Weekly recurrence
    @Published var selectedDaysOfWeek: Set<Int>

    // Monthly recurrence
    @Published var dayOfMonth: Int

    // Recurrence times
    @Published var recurrenceStartTime: String
    @Published var recurrenceEndTime: String

    @Published private(set) var isSaving: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var didSave: Bool = false

    // MARK: - Dependencies

    private let operationsService: OperationsService
    private let sourceOperation: Operation

    // MARK: - Init

    init(
        sourceOperation: Operation,
        operationsService: OperationsService = OperationsService()
    ) {
        self.sourceOperation = sourceOperation
        self.operationsService = operationsService

        // Pre-fill from source operation
        self.name = sourceOperation.name + " (Copy)"
        self.category = sourceOperation.category
        self.description = sourceOperation.description ?? ""
        self.isActive = false // New duplicate starts inactive
        self.isVisible = sourceOperation.isVisible

        // Dates
        self.startDateEnabled = sourceOperation.startDate != nil
        self.startDate = sourceOperation.startDate ?? Date()
        self.endDateEnabled = sourceOperation.endDate != nil
        self.endDate = sourceOperation.endDate ?? Date()
        self.startTime = sourceOperation.startTime ?? ""
        self.endTime = sourceOperation.endTime ?? ""

        // Recurrence
        self.recurrenceType = sourceOperation.recurrenceType
        self.isPerpetual = sourceOperation.recurrenceEndDate == nil
        self.recurrenceEndDate = sourceOperation.recurrenceEndDate ?? Date()

        // Weekly
        if let config = sourceOperation.recurrenceConfig, let days = config.daysOfWeek {
            self.selectedDaysOfWeek = Set(days)
        } else {
            self.selectedDaysOfWeek = []
        }

        // Monthly
        if let config = sourceOperation.recurrenceConfig, let day = config.dayOfMonth {
            self.dayOfMonth = day
        } else {
            self.dayOfMonth = 1
        }

        // Times
        if let config = sourceOperation.recurrenceConfig {
            self.recurrenceStartTime = config.startTime ?? "09:00"
            self.recurrenceEndTime = config.endTime ?? "17:00"
        } else {
            self.recurrenceStartTime = "09:00"
            self.recurrenceEndTime = "17:00"
        }
    }

    // MARK: - Public API

    func duplicateOperation() async {
        resetError()
        isSaving = true
        didSave = false

        // Build recurrence config based on type
        let config = buildRecurrenceConfig()

        let operation = Operation(
            id: UUID(),
            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: normalizedOptional(description),
            isActive: isActive,
            createdAt: Date(),
            startDate: startDateEnabled ? startDate : nil,
            endDate: endDateEnabled ? endDate : nil,
            startTime: normalizedOptional(startTime),
            endTime: normalizedOptional(endTime),
            isVisible: isVisible,
            isRecurring: recurrenceType != .oneTime,
            recurrenceType: recurrenceType,
            recurrenceConfig: config,
            recurrenceEndDate: (recurrenceType != .oneTime && !isPerpetual) ? recurrenceEndDate : nil
        )

        do {
            _ = try await operationsService.create(operation)
            didSave = true
        } catch {
            errorMessage = mapErrorMessage(error)
        }

        isSaving = false
    }

    // MARK: - Recurrence Config Builder

    private func buildRecurrenceConfig() -> RecurrenceConfig? {
        guard recurrenceType != .oneTime else { return nil }

        switch recurrenceType {
        case .oneTime:
            return nil

        case .daily:
            return RecurrenceConfig(
                startTime: normalizedOptional(recurrenceStartTime),
                endTime: normalizedOptional(recurrenceEndTime)
            )

        case .weekly:
            guard !selectedDaysOfWeek.isEmpty else { return nil }
            return RecurrenceConfig(
                daysOfWeek: Array(selectedDaysOfWeek).sorted(),
                startTime: normalizedOptional(recurrenceStartTime),
                endTime: normalizedOptional(recurrenceEndTime)
            )

        case .monthly:
            return RecurrenceConfig(
                dayOfMonth: dayOfMonth,
                startTime: normalizedOptional(recurrenceStartTime),
                endTime: normalizedOptional(recurrenceEndTime)
            )
        }
    }

    // MARK: - Helpers

    private func normalizedOptional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func resetError() {
        errorMessage = nil
    }

    private func mapErrorMessage(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }
        return error.localizedDescription
    }
}
