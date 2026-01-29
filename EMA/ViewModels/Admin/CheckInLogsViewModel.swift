//
//  CheckInLogsViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class CheckInLogsViewModel: ObservableObject {

    enum FilterType: String, CaseIterable, Identifiable {
        case all = "All"
        case active = "In Building"
        case completed = "Checked Out"

        var id: String { rawValue }
    }

    struct CheckInLogRow: Identifiable, Equatable {
        let id: UUID
        let userName: String
        let checkInTime: Date
        let checkOutTime: Date?
        let operationId: UUID
        let terminalId: String?
    }

    // MARK: - Published UI State

    @Published private(set) var allLogs: [CheckInLogRow] = []
    @Published private(set) var logs: [CheckInLogRow] = []
    @Published var selectedFilter: FilterType = .all {
        didSet { applyFilter() }
    }
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let checkInService: CheckInService
    private let usersRepository: UsersRepository
    private let cache: CacheService
    private let realtimeManager = RealtimeManager.shared

    // Realtime
    private var realtimeChannelId: String?
    private var userMap: [UUID: User] = [:]

    // MARK: - Init

    init(
        checkInService: CheckInService = CheckInService(),
        usersRepository: UsersRepository = UsersRepository(),
        cache: CacheService = .shared
    ) {
        self.checkInService = checkInService
        self.usersRepository = usersRepository
        self.cache = cache
    }

    // MARK: - Public API

    func load() async {
        resetError()
        isLoading = true

        do {
            let checkIns = try await checkInService.fetchAllCheckIns()
            let users = try await usersRepository.fetchAllUsers()
            userMap = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })

            allLogs = buildLogRows(from: checkIns, userMap: userMap)
            applyFilter()
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

        // Subscribe to check-in changes
        realtimeChannelId = await realtimeManager.subscribe(
            to: "checkin_log",
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
    }

    func stopRealtimeUpdates() async {
        if let channelId = realtimeChannelId {
            await realtimeManager.unsubscribe(channelId: channelId)
            realtimeChannelId = nil
        }
    }

    private func handleCheckInInsert(_ checkIn: CheckIn) {
        let userName = userMap[checkIn.userId]?.fullName ?? "Unknown User"
        let newRow = CheckInLogRow(
            id: checkIn.id,
            userName: userName,
            checkInTime: checkIn.checkinTime,
            checkOutTime: checkIn.checkoutTime,
            operationId: checkIn.operationId,
            terminalId: checkIn.terminalId
        )
        allLogs.insert(newRow, at: 0) // Add to beginning of list
        applyFilter()
    }

    private func handleCheckInUpdate(_ checkIn: CheckIn) {
        if let index = allLogs.firstIndex(where: { $0.id == checkIn.id }) {
            let userName = userMap[checkIn.userId]?.fullName ?? allLogs[index].userName
            allLogs[index] = CheckInLogRow(
                id: checkIn.id,
                userName: userName,
                checkInTime: checkIn.checkinTime,
                checkOutTime: checkIn.checkoutTime,
                operationId: checkIn.operationId,
                terminalId: checkIn.terminalId
            )
            applyFilter()
        }
    }

    private func handleCheckInDelete(_ checkIn: CheckIn) {
        allLogs.removeAll { $0.id == checkIn.id }
        applyFilter()
    }

    // MARK: - Cache Fallback

    private func loadFromCache() async {
        do {
            let cachedCheckIns: [LocalCheckIn] = try await cache.load(forKey: CacheService.CacheKey.checkIns)
            let cachedUsers: [LocalUser] = try await cache.load(forKey: CacheService.CacheKey.users)

            // Build user map
            let userMap = Dictionary(uniqueKeysWithValues: cachedUsers.map { ($0.id, $0.toAPIModel()) })

            // Convert to API models
            let apiCheckIns = cachedCheckIns.map { $0.toAPIModel() }

            allLogs = buildLogRows(from: apiCheckIns, userMap: userMap)
            applyFilter()

            // Show offline indicator
            if !allLogs.isEmpty {
                errorMessage = "Showing cached data (offline)"
            } else {
                errorMessage = "No cached check-in logs available"
            }
        } catch {
            errorMessage = mapErrorMessage(error)
        }
    }

    private func applyFilter() {
        switch selectedFilter {
        case .all:
            logs = allLogs
        case .active:
            logs = allLogs.filter { $0.checkOutTime == nil }
        case .completed:
            logs = allLogs.filter { $0.checkOutTime != nil }
        }
    }

    private func buildLogRows(from checkIns: [CheckIn], userMap: [UUID: User]) -> [CheckInLogRow] {
        checkIns.map { entry in
            let userName = userMap[entry.userId]?.fullName ?? "Unknown User"
            return CheckInLogRow(
                id: entry.id,
                userName: userName,
                checkInTime: entry.checkinTime,
                checkOutTime: entry.checkoutTime,
                operationId: entry.operationId,
                terminalId: entry.terminalId
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
