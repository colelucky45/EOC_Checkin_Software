//
//  MealServiceViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import Combine

/// ViewModel for admin meal service.
/// Allows admins to manually log meals without scanning.
@MainActor
final class MealServiceViewModel: ObservableObject {

    // MARK: - Published State

    @Published var selectedMealType: String = "Breakfast"
    @Published var quantity: Int = 1
    @Published var selectedUserId: UUID?
    @Published var selectedOperationId: UUID?
    @Published var notes: String = ""

    @Published private(set) var users: [User] = []
    @Published private(set) var operations: [Operation] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isSubmitting: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?

    // MARK: - Constants

    let mealTypes = ["Breakfast", "Lunch", "Dinner"]

    // MARK: - Dependencies

    private let mealService: MealService
    private let operationsService: OperationsService
    private let usersRepository: UsersRepository
    private let realtimeManager = RealtimeManager.shared

    // Realtime
    private var operationsChannelId: String?

    // MARK: - Init

    init(
        mealService: MealService = MealService(),
        operationsService: OperationsService = OperationsService(),
        usersRepository: UsersRepository = UsersRepository()
    ) {
        self.mealService = mealService
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

    func logMeal() async {
        guard quantity > 0 else {
            errorMessage = "Quantity must be greater than zero."
            return
        }

        isSubmitting = true
        errorMessage = nil
        successMessage = nil

        do {
            _ = try await mealService.createMealLog(
                mealType: selectedMealType,
                quantity: quantity,
                servedAt: Date(),
                terminalId: "admin-manual",
                notes: notes.isEmpty ? nil : notes,
                operationId: selectedOperationId,
                userId: selectedUserId
            )

            successMessage = "\(quantity) \(selectedMealType) meal(s) logged successfully."

            Logger.log(
                "Admin manual meal log",
                level: .info,
                category: "MealServiceViewModel",
                metadata: [
                    "mealType": selectedMealType,
                    "quantity": quantity,
                    "userId": selectedUserId?.uuidString ?? "nil",
                    "operationId": selectedOperationId?.uuidString ?? "nil"
                ]
            )

            resetForm()
        } catch {
            let appError = error as? AppError ?? AppError.unexpected(error.localizedDescription)
            errorMessage = appError.userFacingMessage
        }

        isSubmitting = false
    }

    func resetForm() {
        selectedMealType = "Breakfast"
        quantity = 1
        selectedUserId = nil
        selectedOperationId = nil
        notes = ""
        successMessage = nil
        errorMessage = nil
    }

    // MARK: - Realtime

    func startRealtimeUpdates() async {
        // Initial load
        await load()

        // Subscribe to operations changes
        operationsChannelId = await realtimeManager.subscribe(
            to: "operations",
            onInsert: { [weak self] (newOp: Operation) in
                self?.handleOperationInsert(newOp)
            },
            onUpdate: { [weak self] (updated: Operation) in
                self?.handleOperationUpdate(updated)
            },
            onDelete: { [weak self] (deleted: Operation) in
                self?.handleOperationDelete(deleted)
            }
        )
    }

    func stopRealtimeUpdates() async {
        if let channelId = operationsChannelId {
            await realtimeManager.unsubscribe(channelId: channelId)
            operationsChannelId = nil
        }
    }

    private func handleOperationInsert(_ operation: Operation) {
        guard operation.isActive && operation.isVisible else { return }
        operations.append(operation)
        operations.sort { $0.name < $1.name }
    }

    private func handleOperationUpdate(_ operation: Operation) {
        if let index = operations.firstIndex(where: { $0.id == operation.id }) {
            if operation.isActive && operation.isVisible {
                operations[index] = operation
            } else {
                // Operation became inactive or invisible, remove it
                operations.remove(at: index)
            }
        } else if operation.isActive && operation.isVisible {
            // Operation became active/visible, add it
            operations.append(operation)
            operations.sort { $0.name < $1.name }
        }
    }

    private func handleOperationDelete(_ operation: Operation) {
        operations.removeAll { $0.id == operation.id }
    }
}
