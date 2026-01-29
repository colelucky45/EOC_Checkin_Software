//
//  OperationListViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class OperationListViewModel: ObservableObject {

    // MARK: - Published UI State

    @Published private(set) var operations: [Operation] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // Delete state
    @Published var operationToDelete: Operation? {
        didSet { showDeleteConfirmation = operationToDelete != nil }
    }
    @Published var showDeleteConfirmation: Bool = false

    // Duplicate state
    @Published var operationToDuplicate: Operation?

    // MARK: - Dependencies

    private let operationsService: OperationsService
    private let cache: CacheService
    private let realtimeManager = RealtimeManager.shared

    // Realtime
    private var realtimeChannelId: String?

    // MARK: - Init

    init(
        operationsService: OperationsService = OperationsService(),
        cache: CacheService = .shared
    ) {
        self.operationsService = operationsService
        self.cache = cache
    }

    // MARK: - Public API

    func load() async {
        resetError()
        isLoading = true

        do {
            operations = try await operationsService.fetchAll()
        } catch {
            // Fall back to cached data
            await loadFromCache()
        }

        isLoading = false
    }

    // MARK: - Realtime

    func startRealtimeUpdates() async {
        // Initial load
        await load()

        // Subscribe to operation changes
        realtimeChannelId = await realtimeManager.subscribe(
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
        if let channelId = realtimeChannelId {
            await realtimeManager.unsubscribe(channelId: channelId)
            realtimeChannelId = nil
        }
    }

    private func handleOperationInsert(_ operation: Operation) {
        operations.append(operation)
    }

    private func handleOperationUpdate(_ operation: Operation) {
        if let index = operations.firstIndex(where: { $0.id == operation.id }) {
            operations[index] = operation
        }
    }

    private func handleOperationDelete(_ operation: Operation) {
        operations.removeAll { $0.id == operation.id }
    }

    // MARK: - Cache Fallback

    private func loadFromCache() async {
        do {
            let cachedOperations: [LocalOperation] = try await cache.load(forKey: CacheService.CacheKey.operations)

            // Convert to API models
            operations = cachedOperations.map { $0.toAPIModel() }

            // Show offline indicator
            if !operations.isEmpty {
                errorMessage = "Showing cached data (offline)"
            } else {
                errorMessage = "No cached operations available"
            }
        } catch {
            errorMessage = mapErrorMessage(error)
        }
    }

    // MARK: - Delete

    func deleteOperation() async {
        guard let operation = operationToDelete else { return }

        do {
            _ = try await operationsService.delete(operationId: operation.id)
            operations.removeAll { $0.id == operation.id }
            operationToDelete = nil
            Haptics.warning()
        } catch {
            errorMessage = mapErrorMessage(error)
            Haptics.error()
        }
    }

    // MARK: - Helpers

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
