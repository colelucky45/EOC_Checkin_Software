//
//  SystemSettingsRepository.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Repository responsible for global system configuration.
final class SystemSettingsRepository: Sendable {

    private let database: DatabaseProviderProtocol
    private let table = "system_settings"

    init(database: DatabaseProviderProtocol = BackendFactory.current.database) {
        self.database = database
    }

    // MARK: - Fetch

    func fetchSystemSettings() async throws -> SystemSettings {
        let results: [SystemSettings] = try await database.fetchMany(
            from: table,
            filters: [],
            order: nil,
            limit: 1
        )

        guard let settings = results.first else {
            throw AppError.notFound("System settings not found")
        }

        return settings
    }

    // MARK: - Update

    func updateSystemMode(
        settingsId: UUID,
        mode: String
    ) async throws -> SystemSettings {
        let payload = SystemModePayload(mode: mode)
        return try await database.update(payload, in: table, id: settingsId)
    }
}

// MARK: - Supporting Types

private struct SystemModePayload: Encodable, Sendable {
    let mode: String
}
