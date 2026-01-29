//
//  ManualCheckInViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import Combine

/// ViewModel for admin manual check-in/check-out.
/// Allows admins to manually check users in or out without scanning.
@MainActor
final class ManualCheckInViewModel: ObservableObject {

    // MARK: - Published State

    @Published var selectedUserId: UUID?
    @Published var selectedOperationId: UUID?
    @Published var notes: String = ""

    @Published private(set) var users: [User] = []
    @Published private(set) var operations: [Operation] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isPerformingAction: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?

    // MARK: - Dependencies

    private let checkInService: CheckInService
    private let operationsService: OperationsService
    private let usersRepository: UsersRepository

    // MARK: - Init

    init(
        checkInService: CheckInService = CheckInService(),
        operationsService: OperationsService = OperationsService(),
        usersRepository: UsersRepository = UsersRepository()
    ) {
        self.checkInService = checkInService
        self.operationsService = operationsService
        self.usersRepository = usersRepository
    }

    // MARK: - Public API

    func load() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            async let usersTask = usersRepository.fetchAllUsers()
            async let operationsTask = operationsService.fetchAll()

            let (fetchedUsers, fetchedOperations) = try await (usersTask, operationsTask)

            users = fetchedUsers.filter { $0.isActive }.sorted { $0.fullName < $1.fullName }
            operations = fetchedOperations.filter { $0.isActive && $0.isVisible }

            errorMessage = nil
        } catch {
            let appError = error as? AppError ?? AppError.unexpected(error.localizedDescription)
            errorMessage = appError.userFacingMessage
            users = []
            operations = []
        }

        isLoading = false
    }

    func performCheckIn() async {
        guard let userId = selectedUserId else {
            errorMessage = "Please select a user."
            return
        }

        guard let operationId = selectedOperationId else {
            errorMessage = "Please select an operation."
            return
        }

        isPerformingAction = true
        errorMessage = nil
        successMessage = nil

        do {
            _ = try await checkInService.checkInUser(
                userId: userId,
                operationId: operationId,
                terminalId: "admin-manual",
                roleOnCheckin: nil,
                notes: notes.isEmpty ? nil : notes,
                overnight: false
            )

            successMessage = "User checked in successfully."

            Logger.log(
                "Admin manual check-in",
                level: .info,
                category: "ManualCheckInViewModel",
                metadata: ["userId": userId.uuidString, "operationId": operationId.uuidString]
            )

            resetForm()
        } catch {
            let appError = error as? AppError ?? AppError.unexpected(error.localizedDescription)
            errorMessage = appError.userFacingMessage
        }

        isPerformingAction = false
    }

    func performCheckOut() async {
        guard let userId = selectedUserId else {
            errorMessage = "Please select a user."
            return
        }

        isPerformingAction = true
        errorMessage = nil
        successMessage = nil

        do {
            _ = try await checkInService.checkOutUser(
                userId: userId,
                checkoutNote: notes.isEmpty ? nil : notes,
                allowIfOperationInvalid: true
            )

            successMessage = "User checked out successfully."

            Logger.log(
                "Admin manual check-out",
                level: .info,
                category: "ManualCheckInViewModel",
                metadata: ["userId": userId.uuidString]
            )

            resetForm()
        } catch {
            let appError = error as? AppError ?? AppError.unexpected(error.localizedDescription)
            errorMessage = appError.userFacingMessage
        }

        isPerformingAction = false
    }

    func resetForm() {
        selectedUserId = nil
        selectedOperationId = nil
        notes = ""
        successMessage = nil
        errorMessage = nil
    }
}
