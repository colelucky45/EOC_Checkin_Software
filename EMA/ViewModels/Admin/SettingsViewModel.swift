//
//  SettingsViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Published UI State

    @Published private(set) var kioskContext: KioskContext?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let kioskService: KioskService
    private let realtimeManager = RealtimeManager.shared

    // Realtime
    private var kioskSettingsChannelId: String?

    // MARK: - Init

    init(kioskService: KioskService) {
        self.kioskService = kioskService
    }

    // MARK: - Public API

    func load() async {
        resetError()
        isLoading = true

        do {
            kioskContext = try await kioskService.loadKioskContext()
        } catch {
            errorMessage = mapErrorMessage(error)
        }

        isLoading = false
    }

    func setKioskMode(_ mode: KioskMode) async {
        resetError()
        isLoading = true

        do {
            kioskContext = try await kioskService.updateKioskMode(mode)
        } catch {
            errorMessage = mapErrorMessage(error)
        }

        isLoading = false
    }

    // MARK: - Realtime

    func startRealtimeUpdates() async {
        // Initial load
        await load()

        // Subscribe to kiosk_settings changes
        kioskSettingsChannelId = await realtimeManager.subscribe(
            to: "kiosk_settings",
            onUpdate: { [weak self] (updated: KioskSettings) in
                self?.handleKioskSettingsUpdate(updated)
            }
        )
    }

    func stopRealtimeUpdates() async {
        if let channelId = kioskSettingsChannelId {
            await realtimeManager.unsubscribe(channelId: channelId)
            kioskSettingsChannelId = nil
        }
    }

    private func handleKioskSettingsUpdate(_ settings: KioskSettings) {
        // Update kiosk context with new settings
        if let currentContext = kioskContext {
            // Parse the new kiosk mode from the settings
            guard let newKioskMode = KioskMode.fromDatabaseValue(settings.kioskMode) else {
                return
            }

            // Create updated context with new kiosk settings and mode
            kioskContext = KioskContext(
                kioskSettings: settings,
                systemSettings: currentContext.systemSettings,
                kioskMode: newKioskMode,
                systemMode: currentContext.systemMode
            )
        }
    }

    // MARK: - Helpers

    private func resetError() {
        errorMessage = nil
    }

    private func mapErrorMessage(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }
        return error.localizedDescription
    }
}
