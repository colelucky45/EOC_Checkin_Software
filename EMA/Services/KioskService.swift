//
//  KioskService.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

// MARK: - Domain Types (Service-Level)

struct KioskContext: Sendable, Equatable {
    let kioskSettings: KioskSettings
    let systemSettings: SystemSettings
    let kioskMode: KioskMode
    let systemMode: SystemMode
}

enum KioskMode: Sendable, Equatable {
    case checkIn
    case checkOut
    case meal

    static func fromDatabaseValue(_ value: String) -> KioskMode? {
        switch value {
        case "check_in": return .checkIn
        case "check_out": return .checkOut
        case "meal": return .meal
        default: return nil
        }
    }
}

enum SystemMode: Sendable, Equatable {
    case blueSky
    case graySky

    static func fromDatabaseValue(_ value: String) -> SystemMode? {
        switch value {
        case "blue": return .blueSky
        case "gray": return .graySky
        default: return nil
        }
    }
}

// MARK: - Errors

enum KioskServiceError: Error, LocalizedError, Sendable {
    case notAuthenticated
    case notKioskUser
    case invalidKioskMode(String)
    case invalidSystemMode(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to use kiosk functions."
        case .notKioskUser:
            return "Current session is not authorized for kiosk functions."
        case .invalidKioskMode(let mode):
            return "Invalid kiosk mode: \(mode)"
        case .invalidSystemMode(let mode):
            return "Invalid system mode: \(mode)"
        }
    }
}

// MARK: - Kiosk Service

@MainActor
final class KioskService: Sendable {

    private let sessionManager: SessionManager

    private let checkInService: CheckInService
    private let kioskSettingsRepository: KioskSettingsRepository
    private let systemSettingsRepository: SystemSettingsRepository
    private let operationsRepository: OperationsRepository
    private let mealsRepository: MealsRepository
    private let usersRepository: UsersRepository
    private let qrService: QRService
    private let writeQueue: WriteQueue
    private let cache: CacheService

    init(
        sessionManager: SessionManager,
        checkInService: CheckInService? = nil,
        kioskSettingsRepository: KioskSettingsRepository? = nil,
        systemSettingsRepository: SystemSettingsRepository? = nil,
        operationsRepository: OperationsRepository? = nil,
        mealsRepository: MealsRepository? = nil,
        usersRepository: UsersRepository? = nil,
        qrService: QRService? = nil,
        writeQueue: WriteQueue = .shared,
        cache: CacheService = .shared
    ) {
        self.sessionManager = sessionManager

        self.checkInService = checkInService ?? CheckInService()
        self.kioskSettingsRepository = kioskSettingsRepository ?? KioskSettingsRepository()
        self.systemSettingsRepository = systemSettingsRepository ?? SystemSettingsRepository()
        self.operationsRepository = operationsRepository ?? OperationsRepository()
        self.mealsRepository = mealsRepository ?? MealsRepository()
        self.usersRepository = usersRepository ?? UsersRepository()
        self.qrService = qrService ?? QRService()
        self.writeQueue = writeQueue
        self.cache = cache
    }

    // MARK: - Public API

    func getCurrentUserId() -> UUID? {
        return sessionManager.currentUser?.id
    }

    func loadKioskContext() async throws -> KioskContext {
        do {
            _ = try requireSettingsAuthority()

            let terminalId = LocalStorageService.shared.getTerminalId()

            let kioskSettings = try await kioskSettingsRepository.fetchSettings(
                forTerminalId: terminalId
            )
            let systemSettings = try await systemSettingsRepository.fetchSystemSettings()

            return try resolveKioskContext(
                kioskSettings: kioskSettings,
                systemSettings: systemSettings
            )
        } catch {
            throw mapToAppError(error)
        }
    }

    func updateKioskMode(_ mode: KioskMode) async throws -> KioskContext {
        do {
            _ = try requireSettingsAuthority()

            let terminalId = currentTerminalId()

            let updatedSettings = try await kioskSettingsRepository.updateKioskMode(
                terminalId: terminalId,
                kioskMode: databaseValue(for: mode)
            )
            let systemSettings = try await systemSettingsRepository.fetchSystemSettings()

            return try resolveKioskContext(
                kioskSettings: updatedSettings,
                systemSettings: systemSettings
            )
        } catch {
            throw mapToAppError(error)
        }
    }

    func handleQrScan(rawScan: String) async -> Result<User, AppError> {
        do {
            _ = try requireKioskUser()
        } catch {
            return .failure(mapToAppError(error))
        }

        let context: KioskContext
        do {
            context = try await loadKioskContext()
        } catch {
            return .failure(mapToAppError(error))
        }

        let tokenResult = await qrService.resolveToken(from: rawScan)
        let token: QrToken
        switch tokenResult {
        case .success(let resolved):
            token = resolved
        case .failure(let error):
            return .failure(error)
        }

        if token.isExpired {
            return .failure(.validation("QR token has expired."))
        }

        let scannedUser: User
        do {
            scannedUser = try await usersRepository.fetchUser(by: token.userId)
        } catch {
            return .failure(mapUserFetchError(error))
        }

        guard scannedUser.isActive else {
            return .failure(.validation("User is inactive."))
        }

        switch context.kioskMode {
        case .checkIn:
            let result = await checkIn(user: scannedUser, token: token, terminalId: currentTerminalId())
            if case .failure(let error) = result { return .failure(error) }
        case .checkOut:
            let result = await checkOut(user: scannedUser, terminalId: currentTerminalId())
            if case .failure(let error) = result { return .failure(error) }
        case .meal:
            do {
                guard let mealType = currentMealType() else {
                    return .failure(.validation("Meal service is not active at this time."))
                }

                let operationId = try await resolveCurrentOperationId(systemMode: context.systemMode)

                let log = MealLog(
                    id: UUID(),
                    mealType: mealType,
                    quantity: 1,
                    servedAt: Date(),
                    terminalId: currentTerminalId(),
                    notes: nil,
                    operationId: operationId,
                    userId: scannedUser.id
                )

                do {
                    _ = try await mealsRepository.createMealLog(log)
                } catch {
                    // If network error, queue write for offline sync
                    let mappedError = mapToAppError(error)
                    if case .network = mappedError {
                        let queueResult = await queueMeal(log: log)
                        if case .failure(let queueError) = queueResult {
                            return .failure(queueError)
                        }
                    } else {
                        return .failure(mappedError)
                    }
                }
            } catch {
                return .failure(mapToAppError(error))
            }
        }

        return .success(scannedUser)
    }

    func checkIn(user: User, token: QrToken, terminalId: String?) async -> Result<Void, AppError> {
        let context: KioskContext
        do {
            context = try await loadKioskContext()
        } catch {
            return .failure(mapToAppError(error))
        }

        // Get operation_id from token, or fall back to category-based lookup
        let operationId: UUID
        if let tokenOperationId = token.operationId {
            operationId = tokenOperationId
        } else {
            // Fallback for old tokens without operation_id
            let category = operationCategory(for: context.systemMode)
            do {
                guard let resolvedId = try await resolveCurrentOperationId(systemMode: context.systemMode) else {
                    return .failure(.validation("No active operation found for \(category) category."))
                }
                operationId = resolvedId
            } catch {
                return .failure(mapToAppError(error))
            }
        }

        do {
            _ = try await checkInService.checkInUser(
                userId: user.id,
                operationId: operationId,
                terminalId: terminalId,
                roleOnCheckin: nil,
                notes: nil,
                overnight: false
            )
            return .success(())
        } catch {
            // If network error, queue write for offline sync
            let mappedError = mapToAppError(error)
            if case .network = mappedError {
                return await queueCheckIn(
                    userId: user.id,
                    operationId: operationId,
                    terminalId: terminalId
                )
            }
            return .failure(mappedError)
        }
    }

    func checkOut(user: User, terminalId: String?) async -> Result<Void, AppError> {
        do {
            _ = try await checkInService.checkOutUser(
                userId: user.id,
                checkoutNote: nil,
                allowIfOperationInvalid: true
            )
            return .success(())
        } catch {
            // If network error, queue write for offline sync
            let mappedError = mapToAppError(error)
            if case .network = mappedError {
                return await queueCheckOut(userId: user.id)
            }
            return .failure(mappedError)
        }
    }

    // MARK: - Offline Write Queue Helpers

    private func queueCheckIn(
        userId: UUID,
        operationId: UUID,
        terminalId: String?
    ) async -> Result<Void, AppError> {
        do {
            // Create queued write
            let queuedWrite = try QueuedWrite.checkIn(
                userId: userId,
                operationId: operationId,
                terminalId: terminalId,
                roleOnCheckin: nil,
                notes: nil,
                overnight: false
            )

            // Enqueue for sync
            try await writeQueue.enqueue(queuedWrite)

            // Optimistically update cache
            let checkIn = try queuedWrite.asCheckIn()
            let localCheckIn = LocalCheckIn(from: checkIn, syncedAt: nil)
            var cachedCheckIns: [LocalCheckIn] = (try? await cache.load(forKey: CacheService.CacheKey.checkIns)) ?? []
            cachedCheckIns.append(localCheckIn)
            try await cache.save(cachedCheckIns, forKey: CacheService.CacheKey.checkIns)

            Logger.log(
                "Check-in queued for offline sync",
                level: .info,
                category: "KioskService",
                metadata: ["userId": userId.uuidString, "operationId": operationId.uuidString]
            )

            return .success(())
        } catch {
            Logger.log(
                error: .unexpected("Failed to queue check-in: \(error.localizedDescription)"),
                level: .error,
                category: "KioskService",
                context: "queueCheckIn"
            )
            return .failure(.unexpected("Failed to queue check-in for offline sync."))
        }
    }

    private func queueCheckOut(userId: UUID) async -> Result<Void, AppError> {
        do {
            // Find most recent check-in for user
            var cachedCheckIns: [LocalCheckIn] = try await cache.load(forKey: CacheService.CacheKey.checkIns)
            guard let currentCheckIn = cachedCheckIns
                .filter({ $0.userId == userId && $0.checkoutTime == nil })
                .sorted(by: { $0.checkinTime > $1.checkinTime })
                .first else {
                return .failure(.validation("No active check-in found for user."))
            }

            // Create queued write
            let queuedWrite = try QueuedWrite.checkOut(
                checkInId: currentCheckIn.id,
                checkoutNote: nil
            )

            // Enqueue for sync
            try await writeQueue.enqueue(queuedWrite)

            // Optimistically update cache - create new record with checkout time
            if let index = cachedCheckIns.firstIndex(where: { $0.id == currentCheckIn.id }) {
                let updatedCheckIn = CheckIn(
                    id: currentCheckIn.id,
                    userId: currentCheckIn.userId,
                    operationId: currentCheckIn.operationId,
                    checkinTime: currentCheckIn.checkinTime,
                    checkoutTime: Date(),
                    terminalId: currentCheckIn.terminalId,
                    notes: currentCheckIn.notes,
                    overnight: currentCheckIn.overnight,
                    roleOnCheckin: currentCheckIn.roleOnCheckin,
                    checkoutNote: nil
                )
                cachedCheckIns[index] = LocalCheckIn(from: updatedCheckIn, syncedAt: nil)
                try await cache.save(cachedCheckIns, forKey: CacheService.CacheKey.checkIns)
            }

            Logger.log(
                "Check-out queued for offline sync",
                level: .info,
                category: "KioskService",
                metadata: ["userId": userId.uuidString, "checkInId": currentCheckIn.id.uuidString]
            )

            return .success(())
        } catch {
            Logger.log(
                error: .unexpected("Failed to queue check-out: \(error.localizedDescription)"),
                level: .error,
                category: "KioskService",
                context: "queueCheckOut"
            )
            return .failure(.unexpected("Failed to queue check-out for offline sync."))
        }
    }

    private func queueMeal(log: MealLog) async -> Result<Void, AppError> {
        do {
            // Create queued write
            let queuedWrite = try QueuedWrite.meal(
                mealType: log.mealType,
                quantity: log.quantity,
                servedAt: log.servedAt,
                terminalId: log.terminalId,
                notes: log.notes,
                operationId: log.operationId,
                userId: log.userId
            )

            // Enqueue for sync
            try await writeQueue.enqueue(queuedWrite)

            // Optimistically update cache
            let localMeal = LocalMealLog(from: log, syncedAt: nil)
            var cachedMeals: [LocalMealLog] = (try? await cache.load(forKey: CacheService.CacheKey.mealLogs)) ?? []
            cachedMeals.append(localMeal)
            try await cache.save(cachedMeals, forKey: CacheService.CacheKey.mealLogs)

            Logger.log(
                "Meal queued for offline sync",
                level: .info,
                category: "KioskService",
                metadata: ["mealType": log.mealType, "userId": log.userId?.uuidString ?? "nil"]
            )

            return .success(())
        } catch {
            Logger.log(
                error: .unexpected("Failed to queue meal: \(error.localizedDescription)"),
                level: .error,
                category: "KioskService",
                context: "queueMeal"
            )
            return .failure(.unexpected("Failed to queue meal for offline sync."))
        }
    }

    // MARK: - Automatic Meal Logic

    /// Returns schema-aligned meal type values ("Breakfast", "Lunch", "Dinner")
    private func currentMealType(for date: Date = Date()) -> String? {
        let hour = Calendar.current.component(.hour, from: date)

        switch hour {
        case 5...9:
            return "Breakfast"
        case 10...13:
            return "Lunch"
        case 17...20:
            return "Dinner"
        default:
            return nil
        }
    }

    // MARK: - Private Helpers

    private func requireKioskUser() throws -> User {
        guard sessionManager.isAuthenticated,
              let user = sessionManager.currentUser else {
            throw KioskServiceError.notAuthenticated
        }

        guard user.role == "kiosk" else {
            throw KioskServiceError.notKioskUser
        }

        return user
    }

    private func requireSettingsAuthority() throws -> User {
        guard sessionManager.isAuthenticated,
              let user = sessionManager.currentUser else {
            throw KioskServiceError.notAuthenticated
        }

        guard user.role == "kiosk" || user.role == "admin" else {
            throw KioskServiceError.notKioskUser
        }

        return user
    }

    private func resolveCurrentOperationId(systemMode: SystemMode) async throws -> UUID? {
        // FIX: remove direct `client.from("operations")...` query.
        // Use repository to fetch active+visible and select latest by createdAt.
        let category = (systemMode == .blueSky) ? "blue" : "gray"

        let ops = try await operationsRepository.fetchActiveVisibleOperations()
        let filtered = ops.filter { $0.category == category }

        // Prefer latest by createdAt if present; fall back to first.
        // (Operation.createdAt exists in your API model list; we are not inventing new fields here.)
        return filtered.sorted { $0.createdAt > $1.createdAt }.first?.id
    }

    private func currentTerminalId() -> String {
        LocalStorageService.shared.getTerminalId()
    }

    private func operationCategory(for mode: SystemMode) -> String {
        switch mode {
        case .blueSky:
            return "blue"
        case .graySky:
            return "gray"
        }
    }

    private func resolveKioskContext(
        kioskSettings: KioskSettings,
        systemSettings: SystemSettings
    ) throws -> KioskContext {
        guard let kioskMode = KioskMode.fromDatabaseValue(kioskSettings.kioskMode) else {
            throw KioskServiceError.invalidKioskMode(kioskSettings.kioskMode)
        }
        guard let systemMode = SystemMode.fromDatabaseValue(systemSettings.mode) else {
            throw KioskServiceError.invalidSystemMode(systemSettings.mode)
        }

        return KioskContext(
            kioskSettings: kioskSettings,
            systemSettings: systemSettings,
            kioskMode: kioskMode,
            systemMode: systemMode
        )
    }

    private func databaseValue(for mode: KioskMode) -> String {
        switch mode {
        case .checkIn:  return "check_in"
        case .checkOut: return "check_out"
        case .meal:     return "meal"
        }
    }

    private func mapToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }

        if let kioskError = error as? KioskServiceError {
            switch kioskError {
            case .notAuthenticated:
                return .authentication(kioskError.localizedDescription ?? "Authentication required.")
            case .notKioskUser:
                return .authorization(kioskError.localizedDescription ?? "Kiosk authorization required.")
            case .invalidKioskMode:
                return .decoding(kioskError.localizedDescription ?? "Invalid kiosk mode value.")
            case .invalidSystemMode:
                return .decoding(kioskError.localizedDescription ?? "Invalid system mode value.")
            }
        }

        if let networkError = error as? NetworkError {
            return networkError.toAppError()
        }

        if error is DecodingError {
            return .decoding("Failed to decode kiosk response.")
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return NetworkError.from(error).toAppError()
        }

        return .unexpected(error.localizedDescription)
    }

    private func mapUserFetchError(_ error: Error) -> AppError {
        let appError = mapToAppError(error)

        switch appError {
        case .unexpected:
            return .notFound("User not found.")
        default:
            return appError
        }
    }
}
