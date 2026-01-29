//
//  ResponderHomeViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ResponderHomeViewModel: ObservableObject {

    // MARK: - Published UI State

    @Published private(set) var isCheckedIn: Bool?
    @Published private(set) var checkInTime: Date?
    @Published private(set) var operationName: String = "Unknown Operation"
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let checkInService: CheckInService
    private let operationsService: OperationsService
    private let cache: CacheService
    private let realtimeManager = RealtimeManager.shared

    // Realtime
    private var checkInsChannelId: String?
    private var operationsChannelId: String?
    private var currentUserId: UUID?

    // MARK: - Init

    init(
        checkInService: CheckInService = CheckInService(),
        operationsService: OperationsService = OperationsService(),
        cache: CacheService = .shared,
        session: SessionManager
    ) {
        self.checkInService = checkInService
        self.operationsService = operationsService
        self.cache = cache
    }

    // MARK: - Public API

    func load(userId: UUID) async {
        currentUserId = userId
        resetError()
        isLoading = true

        do {
            let currentCheckIn = try await checkInService.fetchCurrentCheckIn(userId: userId)

            if let currentCheckIn {
                isCheckedIn = true
                checkInTime = currentCheckIn.checkinTime

                let operation = try await operationsService.fetch(by: currentCheckIn.operationId)
                operationName = operation.name
            } else {
                isCheckedIn = false
                checkInTime = nil
                operationName = "Not Checked In"
            }
        } catch {
            // Fall back to cached data
            await loadFromCache(userId: userId)
        }

        isLoading = false
    }

    // MARK: - Realtime

    func startRealtimeUpdates(userId: UUID) async {
        currentUserId = userId

        // Initial load
        await load(userId: userId)

        // Subscribe to this user's check-in changes
        checkInsChannelId = await realtimeManager.subscribe(
            to: "checkin_log",
            filter: "user_id=eq.\(userId.uuidString)",
            onInsert: { [weak self] (newCheckIn: CheckIn) in
                self?.handleCheckInInsert(newCheckIn)
            },
            onUpdate: { [weak self] (updated: CheckIn) in
                self?.handleCheckInUpdate(updated)
            },
            onDelete: { [weak self] (deleted: CheckIn) in
                self?.handleCheckInDelete(deleted)
            }
        )

        // Subscribe to operations (to see when operation details change)
        operationsChannelId = await realtimeManager.subscribe(
            to: "operations",
            onUpdate: { [weak self] (updated: Operation) in
                self?.handleOperationUpdate(updated)
            }
        )
    }

    func stopRealtimeUpdates() async {
        if let channelId = checkInsChannelId {
            await realtimeManager.unsubscribe(channelId: channelId)
            checkInsChannelId = nil
        }
        if let channelId = operationsChannelId {
            await realtimeManager.unsubscribe(channelId: channelId)
            operationsChannelId = nil
        }
    }

    private func handleCheckInInsert(_ checkIn: CheckIn) {
        // User just checked in
        isCheckedIn = true
        checkInTime = checkIn.checkinTime

        // Fetch operation name
        Task {
            do {
                let operation = try await operationsService.fetch(by: checkIn.operationId)
                operationName = operation.name
            } catch {
                operationName = "Unknown Operation"
            }
        }
    }

    private func handleCheckInUpdate(_ checkIn: CheckIn) {
        if checkIn.checkoutTime != nil {
            // User checked out
            isCheckedIn = false
            checkInTime = nil
            operationName = "Not Checked In"
        } else {
            // Check-in updated but still active
            checkInTime = checkIn.checkinTime

            // Fetch operation name in case it changed
            Task {
                do {
                    let operation = try await operationsService.fetch(by: checkIn.operationId)
                    operationName = operation.name
                } catch {
                    operationName = "Unknown Operation"
                }
            }
        }
    }

    private func handleCheckInDelete(_ checkIn: CheckIn) {
        // Check-in record deleted
        isCheckedIn = false
        checkInTime = nil
        operationName = "Not Checked In"
    }

    private func handleOperationUpdate(_ operation: Operation) {
        // If this is the operation the user is checked into, update the name
        // We would need to track the current operation ID to know for sure
        // For now, we'll just refresh if checked in
        if isCheckedIn == true, let userId = currentUserId {
            Task {
                do {
                    let currentCheckIn = try await checkInService.fetchCurrentCheckIn(userId: userId)
                    if let currentCheckIn, currentCheckIn.operationId == operation.id {
                        operationName = operation.name
                    }
                } catch {
                    // Ignore error for realtime update
                }
            }
        }
    }

    // MARK: - Cache Fallback

    private func loadFromCache(userId: UUID) async {
        do {
            let cachedCheckIns: [LocalCheckIn] = try await cache.load(forKey: CacheService.CacheKey.checkIns)
            let cachedOperations: [LocalOperation] = try await cache.load(forKey: CacheService.CacheKey.operations)

            // Find user's current check-in (no checkout time)
            if let currentCheckIn = cachedCheckIns.first(where: { $0.userId == userId && $0.checkoutTime == nil }) {
                isCheckedIn = true
                checkInTime = currentCheckIn.checkinTime

                // Find operation
                if let operation = cachedOperations.first(where: { $0.id == currentCheckIn.operationId }) {
                    operationName = operation.name
                } else {
                    operationName = "Unknown Operation"
                }
            } else {
                isCheckedIn = false
                checkInTime = nil
                operationName = "Not Checked In"
            }

            // Show offline indicator
            errorMessage = "Showing cached data (offline)"
        } catch {
            errorMessage = mapErrorMessage(error)
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
