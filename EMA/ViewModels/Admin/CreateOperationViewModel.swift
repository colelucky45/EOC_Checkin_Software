//
//  CreateOperationViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class CreateOperationViewModel: ObservableObject {

    // MARK: - Published Form State

    @Published var name: String = ""
    @Published var category: String = "blue"
    @Published var description: String = ""
    @Published var isActive: Bool = false
    @Published var isVisible: Bool = true
    @Published var startDateEnabled: Bool = false
    @Published var endDateEnabled: Bool = false
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date()
    @Published var startTime: String = ""
    @Published var endTime: String = ""

    // MARK: - Recurrence Fields

    @Published var recurrenceType: RecurrenceType = .oneTime
    @Published var isPerpetual: Bool = true
    @Published var recurrenceEndDate: Date = Date()

    // Weekly recurrence
    @Published var selectedDaysOfWeek: Set<Int> = [] // 0=Sunday, 6=Saturday

    // Monthly recurrence
    @Published var dayOfMonth: Int = 1

    // Recurrence times
    @Published var recurrenceStartTime: String = "09:00"
    @Published var recurrenceEndTime: String = "17:00"

    @Published private(set) var isSaving: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var didSave: Bool = false

    // MARK: - Dependencies

    private let operationsService: OperationsService

    // MARK: - Init

    init(operationsService: OperationsService = OperationsService()) {
        self.operationsService = operationsService
    }

    // MARK: - Public API

    func createOperation() async {
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
            Haptics.success()
        } catch {
            errorMessage = mapErrorMessage(error)
            Haptics.error()
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
