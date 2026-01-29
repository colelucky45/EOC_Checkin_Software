//
//  ResponderHistoryViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ResponderHistoryViewModel: ObservableObject {

    struct HistoryRow: Identifiable, Equatable {
        let id: UUID
        let operationName: String
        let checkInTime: Date
        let checkOutTime: Date?
        let duration: String?
        let notes: String?
    }

    // MARK: - Published UI State

    @Published private(set) var history: [HistoryRow] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let checkInService: CheckInService
    private let operationsService: OperationsService
    private let cache: CacheService

    // MARK: - Init

    init(
        checkInService: CheckInService = CheckInService(),
        operationsService: OperationsService = OperationsService(),
        cache: CacheService = .shared
    ) {
        self.checkInService = checkInService
        self.operationsService = operationsService
        self.cache = cache
    }

    // MARK: - Public API

    func load(userId: UUID) async {
        resetError()
        isLoading = true

        do {
            let checkIns = try await checkInService.fetchUserHistory(userId: userId)

            // Fetch all operations to resolve names
            let operations = try await operationsService.fetchAll()
            let operationMap = Dictionary(uniqueKeysWithValues: operations.map { ($0.id, $0) })

            history = buildHistoryRows(from: checkIns, operationMap: operationMap)
        } catch {
            // Fall back to cached data
            await loadFromCache(userId: userId)
        }

        isLoading = false
    }

    // MARK: - Cache Fallback

    private func loadFromCache(userId: UUID) async {
        do {
            let cachedCheckIns: [LocalCheckIn] = try await cache.load(forKey: CacheService.CacheKey.checkIns)
            let cachedOperations: [LocalOperation] = try await cache.load(forKey: CacheService.CacheKey.operations)

            // Filter check-ins for this user
            let userCheckIns = cachedCheckIns.filter { $0.userId == userId }

            // Build operation map
            let operationMap = Dictionary(uniqueKeysWithValues: cachedOperations.map { ($0.id, $0.toAPIModel()) })

            // Convert local to API models for display
            let apiCheckIns = userCheckIns.map { $0.toAPIModel() }

            history = buildHistoryRows(from: apiCheckIns, operationMap: operationMap)

            // Show offline indicator
            if !history.isEmpty {
                errorMessage = "Showing cached data (offline)"
            } else {
                errorMessage = "No cached history available"
            }
        } catch {
            errorMessage = mapErrorMessage(error)
        }
    }

    private func buildHistoryRows(from checkIns: [CheckIn], operationMap: [UUID: Operation]) -> [HistoryRow] {
        checkIns.map { checkIn in
            let operationName = operationMap[checkIn.operationId]?.name ?? "Unknown Operation"

            return HistoryRow(
                id: checkIn.id,
                operationName: operationName,
                checkInTime: checkIn.checkinTime,
                checkOutTime: checkIn.checkoutTime,
                duration: checkIn.formattedDuration,
                notes: checkIn.notes
            )
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
