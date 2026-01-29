//
//  CheckinApp.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

@main
struct CheckInApp: App {

    @StateObject private var appState = AppState()
    @StateObject private var session = SessionManager()

    init() {
        let terminalId = LocalStorageService.shared.getTerminalId()
        print("📟 Kiosk terminal_id:", terminalId)
    }

    var body: some Scene {
        WindowGroup {
            RoleRouter()
                .environmentObject(appState)
                .environmentObject(session)
        }
    }
}
