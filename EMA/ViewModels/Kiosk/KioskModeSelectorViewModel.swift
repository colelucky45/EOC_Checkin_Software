//
//  KioskModeSelectorViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class KioskModeSelectorViewModel: ObservableObject {

    // MARK: - Published UI State

    @Published private(set) var kioskContext: KioskContext?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let kioskService: KioskService

    // MARK: - Init

    init(
        kioskService: KioskService
    ) {
        self.kioskService = kioskService
    }

    // MARK: - Public API

    /// Loads the current kiosk + system context.
    /// Called on view appear.
    func load() async {
        resetError()
        isLoading = true

        do {
            kioskContext = try await kioskService.loadKioskContext()

            // DEBUG: Log the current user info
            if let userId = kioskService.getCurrentUserId() {
                Logger.log(
                    "🔍 DEBUG: Logged in user ID: \(userId)",
                    level: .info,
                    category: "KioskModeSelectorViewModel"
                )
            } else {
                Logger.log(
                    "🔍 DEBUG: No user logged in!",
                    level: .warning,
                    category: "KioskModeSelectorViewModel"
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Updates the kiosk mode (admin-only flow).
    func setKioskMode(_ mode: KioskMode) async {
        resetError()
        isLoading = true

        do {
            kioskContext = try await kioskService.updateKioskMode(mode)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Helpers

    private func resetError() {
        errorMessage = nil
    }
}
