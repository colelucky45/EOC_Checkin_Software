//
//  SystemSettingsService.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Business orchestration for global system configuration.
/// Backed by `system_settings` (expected single-row table).
final class SystemSettingsService: @unchecked Sendable {

    // Schema-validated allowed values: 'blue' | 'gray'
    enum SystemMode: String, CaseIterable, Sendable {
        case blue
        case gray
    }

    private let repository: SystemSettingsRepository

    init(repository: SystemSettingsRepository = SystemSettingsRepository()) {
        self.repository = repository
    }

    // MARK: - Read

    /// Fetches the single global system settings row.
    func fetch() async throws -> SystemSettings {
        do {
            return try await repository.fetchSystemSettings()
        } catch {
            let appError = mapToAppError(error)
            Logger.log(error: appError, level: .error, category: "SystemSettingsService", context: "fetch")
            throw appError
        }
    }

    /// Convenience accessor for mode only.
    /// Falls back to 'blue' mode if system settings not found (e.g., new installation).
    func fetchMode() async throws -> SystemMode {
        do {
            let settings = try await fetch()
            return try parseMode(settings.mode)
        } catch let appError as AppError where appError.isNotFound {
            Logger.log(
                "System settings not found, defaulting to blue mode",
                level: .warning,
                category: "SystemSettingsService"
            )
            return .blue
        }
    }

    // MARK: - Write (Admin)

    /// Updates the system mode (blue/gray). Admin-only by RLS.
    func setMode(_ mode: SystemMode) async throws -> SystemSettings {
        do {
            let current = try await repository.fetchSystemSettings()

            let updated = try await repository.updateSystemMode(
                settingsId: current.id,
                mode: mode.rawValue
            )

            Logger.log(
                "System mode updated",
                level: .info,
                category: "SystemSettingsService",
                metadata: ["settingsId": current.id.uuidString, "mode": mode.rawValue]
            )

            return updated
        } catch {
            let appError = mapToAppError(error)
            Logger.log(error: appError, level: .error, category: "SystemSettingsService", context: "setMode")
            throw appError
        }
    }

    /// Toggles system mode between blue <-> gray.
    func toggleMode() async throws -> SystemSettings {
        let currentMode = try await fetchMode()
        let next: SystemMode = (currentMode == .blue) ? .gray : .blue
        return try await setMode(next)
    }

    // MARK: - Helpers

    private func parseMode(_ raw: String) throws -> SystemMode {
        let normalized = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let mode = SystemMode(rawValue: normalized) {
            return mode
        }
        // Don’t invent additional DB values. Treat unexpected values as server/data issue.
        throw AppError.decoding("Invalid system mode value: \(raw)")
    }

    private func mapToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }

        if let networkError = error as? NetworkError {
            return networkError.toAppError()
        }

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return NetworkError.from(error).toAppError()
        }

        // Repository throws a 404 NSError when settings row missing.
        if nsError.domain == "SystemSettingsRepository", nsError.code == 404 {
            return .notFound(nsError.localizedDescription)
        }

        return .unexpected(error.localizedDescription)
    }
}
