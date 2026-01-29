//
//  AppState.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import SwiftUI
import Combine

/// Global application-wide state container.
/// Used by the root App struct and passed down into major view flows.
@MainActor
final class AppState: ObservableObject, Sendable {
    
    
    // MARK: - Published State
    
    /// Whether the app is currently loading global resources (session restore, system settings, etc.).
    @Published var isLoading: Bool = true
    
    /// Global error presentation.
    @Published var globalError: AppError?
    
    /// Tracks if the app is running in kiosk mode (determined by SessionManager + RoleRouter).
    @Published var isKioskMode: Bool = false
    
    /// Tracks whether the app is in blue sky or gray sky mode (comes from SystemSettingsService).
    @Published var systemMode: String = "blue"
    
    /// Used to force UI refreshes in situations where major state changes occur.
    @Published var refreshID = UUID()
    
    // MARK: - Initialization

    init() {
        // AppState initialization complete
    }

    // MARK: - Global Error Handling

    func presentError(_ error: Error) {
        if let appError = error as? AppError {
            self.globalError = appError
        } else {
            self.globalError = AppError.unexpected(error.localizedDescription)
        }
    }

    func clearError() {
        self.globalError = nil
    }

    // MARK: - Mode Updates

    func updateSystemMode(_ newMode: String) {
        systemMode = newMode
    }

    func setKioskMode(_ isKiosk: Bool) {
        isKioskMode = isKiosk
    }

    // MARK: - UI Refresh Trigger

    func forceRefresh() {
        refreshID = UUID()
    }
}
