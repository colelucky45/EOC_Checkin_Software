//
//  LocalSystemSettings.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Local/offline representation of system settings (blue/gray mode).
/// Used for offline display of system mode.
struct LocalSystemSettings: Identifiable, Codable, Equatable, Sendable {

    let id: UUID
    let mode: String          // "blue" or "gray"
    let updatedAt: Date?

    /// Timestamp of last successful sync with server.
    let syncedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case mode
        case updatedAt = "updated_at"
        case syncedAt  = "synced_at"
    }

    var isBlueSky: Bool {
        mode == "blue"
    }

    var isGraySky: Bool {
        mode == "gray"
    }
}

extension LocalSystemSettings {

    /// Create a local record from the API model.
    init(from api: SystemSettings, syncedAt: Date? = Date()) {
        self.id = api.id
        self.mode = api.mode
        self.updatedAt = api.updatedAt
        self.syncedAt = syncedAt
    }

    /// Converts back to API model.
    func toAPIModel() -> SystemSettings {
        SystemSettings(
            id: id,
            mode: mode,
            updatedAt: updatedAt
        )
    }
}
