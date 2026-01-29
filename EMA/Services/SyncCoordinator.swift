//
//  SyncCoordinator.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Registers and coordinates sync steps for offline support.
/// Wires together SyncEngine, Services, and CacheService.
@MainActor
final class SyncCoordinator {

    // MARK: - Dependencies

    private let syncEngine: SyncEngine
    private let cache: CacheService
    private let writeQueue: WriteQueue
    private let usersRepository: UsersRepository
    private let operationsRepository: OperationsRepository
    private let checkInRepository: CheckInRepository
    private let mealsRepository: MealsRepository
    private let systemSettingsRepository: SystemSettingsRepository
    private let checkInService: CheckInService
    private let mealService: MealService

    // MARK: - Init

    init(
        syncEngine: SyncEngine = SyncEngine(),
        cache: CacheService = .shared,
        writeQueue: WriteQueue = .shared,
        usersRepository: UsersRepository = UsersRepository(),
        operationsRepository: OperationsRepository = OperationsRepository(),
        checkInRepository: CheckInRepository = CheckInRepository(),
        mealsRepository: MealsRepository = MealsRepository(),
        systemSettingsRepository: SystemSettingsRepository = SystemSettingsRepository(),
        checkInService: CheckInService = CheckInService(),
        mealService: MealService = MealService()
    ) {
        self.syncEngine = syncEngine
        self.cache = cache
        self.writeQueue = writeQueue
        self.usersRepository = usersRepository
        self.operationsRepository = operationsRepository
        self.checkInRepository = checkInRepository
        self.mealsRepository = mealsRepository
        self.systemSettingsRepository = systemSettingsRepository
        self.checkInService = checkInService
        self.mealService = mealService
    }

    // MARK: - Registration

    /// Registers all sync steps. Call once on app start or session restore.
    func registerSyncSteps() async {
        // CRITICAL: Sync writes FIRST before reading
        // This ensures offline writes are pushed before pulling fresh data
        await syncEngine.register(step: SyncStep(name: "sync-write-queue") { [weak self] in
            try await self?.syncWriteQueue()
        })

        await syncEngine.register(step: SyncStep(name: "sync-users") { [weak self] in
            try await self?.syncUsers()
        })

        await syncEngine.register(step: SyncStep(name: "sync-operations") { [weak self] in
            try await self?.syncOperations()
        })

        await syncEngine.register(step: SyncStep(name: "sync-checkins") { [weak self] in
            try await self?.syncCheckIns()
        })

        await syncEngine.register(step: SyncStep(name: "sync-meals") { [weak self] in
            try await self?.syncMealLogs()
        })

        await syncEngine.register(step: SyncStep(name: "sync-system-settings") { [weak self] in
            try await self?.syncSystemSettings()
        })

        Logger.log(
            "Sync steps registered",
            level: .info,
            category: "SyncCoordinator"
        )
    }

    /// Triggers an immediate sync.
    func syncNow(reason: String? = nil) async {
        await syncEngine.syncNow(reason: reason)
    }

    /// Clears all cached data and resets sync steps.
    func reset() async throws {
        try await cache.clearAll()
        await syncEngine.resetSteps()

        Logger.log(
            "Sync coordinator reset",
            level: .warning,
            category: "SyncCoordinator"
        )
    }

    // MARK: - Sync Step Implementations

    private func syncUsers() async throws {
        // Fetch from API
        let apiUsers = try await usersRepository.fetchAllUsers()

        // Convert to Local models
        let localUsers = apiUsers.map { LocalUser(from: $0, syncedAt: Date()) }

        // Save to cache
        try await cache.save(localUsers, forKey: CacheService.CacheKey.users)

        Logger.log(
            "Users synced to cache",
            level: .info,
            category: "SyncCoordinator",
            metadata: ["count": apiUsers.count]
        )
    }

    private func syncOperations() async throws {
        // Fetch from API
        let apiOperations = try await operationsRepository.fetchAllOperations()

        // Convert to Local models
        let localOperations = apiOperations.map { LocalOperation(from: $0, syncedAt: Date()) }

        // Save to cache
        try await cache.save(localOperations, forKey: CacheService.CacheKey.operations)

        Logger.log(
            "Operations synced to cache",
            level: .info,
            category: "SyncCoordinator",
            metadata: ["count": apiOperations.count]
        )
    }

    private func syncCheckIns() async throws {
        do {
            // Fetch from API
            let apiCheckIns = try await checkInRepository.fetchAllCheckIns()

            // Convert to Local models
            let localCheckIns = apiCheckIns.map { LocalCheckIn(from: $0, syncedAt: Date()) }

            // Save to cache
            try await cache.save(localCheckIns, forKey: CacheService.CacheKey.checkIns)

            Logger.log(
                "Check-ins synced to cache",
                level: .info,
                category: "SyncCoordinator",
                metadata: ["count": apiCheckIns.count]
            )
        } catch {
            // Kiosk users can't read check-ins - this is expected
            // Log but don't fail the sync
            Logger.log(
                "Check-ins sync skipped (likely permission denied for kiosk role)",
                level: .info,
                category: "SyncCoordinator"
            )

            // Clear any stale cached check-ins
            let emptyCheckIns: [LocalCheckIn] = []
            try? await cache.save(emptyCheckIns, forKey: CacheService.CacheKey.checkIns)
        }
    }

    private func syncMealLogs() async throws {
        do {
            // Fetch from API
            let apiMealLogs = try await mealsRepository.fetchAllMealLogs()

            // Convert to Local models
            let localMealLogs = apiMealLogs.map { LocalMealLog(from: $0, syncedAt: Date()) }

            // Save to cache
            try await cache.save(localMealLogs, forKey: CacheService.CacheKey.mealLogs)

            Logger.log(
                "Meal logs synced to cache",
                level: .info,
                category: "SyncCoordinator",
                metadata: ["count": apiMealLogs.count]
            )
        } catch {
            // Kiosk users can't read meals - this is expected
            // Log but don't fail the sync
            Logger.log(
                "Meal logs sync skipped (likely permission denied for kiosk role)",
                level: .info,
                category: "SyncCoordinator"
            )

            // Clear any stale cached meal logs
            let emptyMealLogs: [LocalMealLog] = []
            try? await cache.save(emptyMealLogs, forKey: CacheService.CacheKey.mealLogs)
        }
    }

    private func syncSystemSettings() async throws {
        do {
            // Fetch from API (single-row table)
            let apiSettings = try await systemSettingsRepository.fetchSystemSettings()

            // Convert to Local model
            let localSettings = LocalSystemSettings(from: apiSettings, syncedAt: Date())

            // Save to cache (as single-element array for consistency)
            try await cache.save([localSettings], forKey: CacheService.CacheKey.systemSettings)

            Logger.log(
                "System settings synced to cache",
                level: .info,
                category: "SyncCoordinator",
                metadata: ["mode": apiSettings.mode]
            )
        } catch {
            // System settings not found - this is OK for new installations
            // Log but don't fail the sync
            Logger.log(
                error: .notFound("System settings not found"),
                level: .info,
                category: "SyncCoordinator",
                context: "syncSystemSettings"
            )

            // Clear any stale cached settings
            let emptySettings: [LocalSystemSettings] = []
            try? await cache.save(emptySettings, forKey: CacheService.CacheKey.systemSettings)
        }
    }

    // MARK: - Write Queue Sync

    private func syncWriteQueue() async throws {
        let pendingWrites = try await writeQueue.pendingWrites()

        guard !pendingWrites.isEmpty else {
            Logger.log(
                "Write queue empty, skipping",
                level: .debug,
                category: "SyncCoordinator"
            )
            return
        }

        Logger.log(
            "Syncing write queue",
            level: .info,
            category: "SyncCoordinator",
            metadata: ["pendingCount": pendingWrites.count]
        )

        for write in pendingWrites {
            do {
                try await writeQueue.markSyncing(write.id)
                try await replayWrite(write)
                try await writeQueue.remove(write.id)

                Logger.log(
                    "Write synced successfully",
                    level: .info,
                    category: "SyncCoordinator",
                    metadata: [
                        "id": write.id.uuidString,
                        "type": write.type.rawValue
                    ]
                )
            } catch {
                try await writeQueue.markFailed(write.id, error: error)

                Logger.log(
                    error: .unexpected("Write sync failed: \(error.localizedDescription)"),
                    level: .error,
                    category: "SyncCoordinator",
                    context: "Write ID: \(write.id.uuidString), Type: \(write.type.rawValue)"
                )

                // Continue processing other writes instead of failing entire sync
            }
        }
    }

    private func replayWrite(_ write: QueuedWrite) async throws {
        switch write.type {
        case .checkIn:
            let checkIn = try write.asCheckIn()
            _ = try await checkInService.checkInUser(
                userId: checkIn.userId,
                operationId: checkIn.operationId,
                terminalId: checkIn.terminalId,
                roleOnCheckin: checkIn.roleOnCheckin,
                notes: checkIn.notes,
                overnight: checkIn.overnight ?? false
            )

        case .checkOut:
            let checkOut = try write.asCheckOut()
            _ = try await checkInService.checkOut(
                checkInId: checkOut.checkInId,
                checkoutNote: checkOut.checkoutNote
            )

        case .meal:
            let meal = try write.asMealLog()
            _ = try await mealService.createMealLog(
                id: meal.id,
                mealType: meal.mealType,
                quantity: meal.quantity,
                servedAt: meal.servedAt,
                terminalId: meal.terminalId,
                notes: meal.notes,
                operationId: meal.operationId,
                userId: meal.userId
            )
        }
    }
}
