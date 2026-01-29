//
//  KioskSettingsRepository.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Repository responsible for reading and updating kiosk configuration.
final class KioskSettingsRepository: Sendable {

    private let database: DatabaseProviderProtocol
    private let table = "kiosk_settings"

    init(database: DatabaseProviderProtocol = BackendFactory.current.database) {
        self.database = database
    }

    // MARK: - Fetch

    func fetchSettings(forTerminalId terminalId: String) async throws -> KioskSettings {
        try await database.fetchOne(
            from: table,
            filter: .equals("terminal_id", terminalId)
        )
    }

    // MARK: - Update

    func updateKioskMode(
        terminalId: String,
        kioskMode: String
    ) async throws -> KioskSettings {
        let payload = KioskModePayload(kioskMode: kioskMode)
        return try await database.update(
            payload,
            in: table,
            filter: .equals("terminal_id", terminalId)
        )
    }
}

// MARK: - Supporting Types

private struct KioskModePayload: Encodable, Sendable {
    let kioskMode: String

    enum CodingKeys: String, CodingKey {
        case kioskMode = "kiosk_mode"
    }
}
