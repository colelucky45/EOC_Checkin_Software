//
//  MealLogsViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class MealLogsViewModel: ObservableObject {

    struct MealLogRow: Identifiable, Equatable {
        let id: UUID
        let mealSummary: String
        let servedAt: Date
        let userName: String
        let operationId: UUID?
        let terminalId: String?
    }

    // MARK: - Published UI State

    @Published private(set) var logs: [MealLogRow] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let mealService: MealService
    private let usersRepository: UsersRepository
    private let cache: CacheService
    private let realtimeManager = RealtimeManager.shared

    // Realtime
    private var realtimeChannelId: String?
    private var userMap: [UUID: User] = [:]

    // MARK: - Init

    init(
        mealService: MealService = MealService(),
        usersRepository: UsersRepository = UsersRepository(),
        cache: CacheService = .shared
    ) {
        self.mealService = mealService
        self.usersRepository = usersRepository
        self.cache = cache
    }

    // MARK: - Public API

    func load() async {
        resetError()
        isLoading = true

        do {
            let mealLogs = try await mealService.fetchAllMealLogs()
            let users = try await usersRepository.fetchAllUsers()
            userMap = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })

            logs = buildLogRows(from: mealLogs, userMap: userMap)
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

        // Subscribe to meal log changes
        realtimeChannelId = await realtimeManager.subscribe(
            to: "meals_log",
            onInsert: { [weak self] (newMeal: MealLog) in
                self?.handleMealInsert(newMeal)
            },
            onUpdate: { [weak self] (updated: MealLog) in
                self?.handleMealUpdate(updated)
            },
            onDelete: { [weak self] (deleted: MealLog) in
                self?.handleMealDelete(deleted)
            }
        )
    }

    func stopRealtimeUpdates() async {
        if let channelId = realtimeChannelId {
            await realtimeManager.unsubscribe(channelId: channelId)
            realtimeChannelId = nil
        }
    }

    private func handleMealInsert(_ mealLog: MealLog) {
        let userName = mealLog.userId.flatMap { userMap[$0]?.fullName } ?? "Unassigned"
        let newRow = MealLogRow(
            id: mealLog.id,
            mealSummary: mealLog.mealSummary,
            servedAt: mealLog.servedAt,
            userName: userName,
            operationId: mealLog.operationId,
            terminalId: mealLog.terminalId
        )
        logs.insert(newRow, at: 0) // Add to beginning of list
    }

    private func handleMealUpdate(_ mealLog: MealLog) {
        if let index = logs.firstIndex(where: { $0.id == mealLog.id }) {
            let userName = mealLog.userId.flatMap { userMap[$0]?.fullName } ?? logs[index].userName
            logs[index] = MealLogRow(
                id: mealLog.id,
                mealSummary: mealLog.mealSummary,
                servedAt: mealLog.servedAt,
                userName: userName,
                operationId: mealLog.operationId,
                terminalId: mealLog.terminalId
            )
        }
    }

    private func handleMealDelete(_ mealLog: MealLog) {
        logs.removeAll { $0.id == mealLog.id }
    }

    // MARK: - Cache Fallback

    private func loadFromCache() async {
        do {
            let cachedMealLogs: [LocalMealLog] = try await cache.load(forKey: CacheService.CacheKey.mealLogs)
            let cachedUsers: [LocalUser] = try await cache.load(forKey: CacheService.CacheKey.users)

            // Build user map
            let userMap = Dictionary(uniqueKeysWithValues: cachedUsers.map { ($0.id, $0.toAPIModel()) })

            // Convert to API models
            let apiMealLogs = cachedMealLogs.map { $0.toAPIModel() }

            logs = buildLogRows(from: apiMealLogs, userMap: userMap)

            // Show offline indicator
            if !logs.isEmpty {
                errorMessage = "Showing cached data (offline)"
            } else {
                errorMessage = "No cached meal logs available"
            }
        } catch {
            errorMessage = mapErrorMessage(error)
        }
    }

    private func buildLogRows(from mealLogs: [MealLog], userMap: [UUID: User]) -> [MealLogRow] {
        mealLogs.map { entry in
            let userName = entry.userId.flatMap { userMap[$0]?.fullName } ?? "Unassigned"
            return MealLogRow(
                id: entry.id,
                mealSummary: entry.mealSummary,
                servedAt: entry.servedAt,
                userName: userName,
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
