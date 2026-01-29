//
//  LocalStorageService.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

final class LocalStorageService {

    static let shared = LocalStorageService()

    private init() {}

    private let terminalIdKey = "kiosk_terminal_id"

    func getTerminalId() -> String {
        if let existing = UserDefaults.standard.string(forKey: terminalIdKey) {
            return existing
        }

        let newTerminalId = UUID().uuidString
        UserDefaults.standard.set(newTerminalId, forKey: terminalIdKey)
        return newTerminalId
    }

    /// Explicit reset (admin / debug use only).
    /// Treats the device as a brand-new kiosk.
    func resetTerminalId() {
        UserDefaults.standard.removeObject(forKey: terminalIdKey)
    }
}

