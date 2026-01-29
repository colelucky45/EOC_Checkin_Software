//
//  ActivationModeViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ActivationModeViewModel: ObservableObject {

    // MARK: - Published UI State

    @Published private(set) var currentMode: SystemSettingsService.SystemMode?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let systemSettingsService: SystemSettingsService

    // MARK: - Init

    init(systemSettingsService: SystemSettingsService = SystemSettingsService()) {
        self.systemSettingsService = systemSettingsService
    }

    // MARK: - Public API

    func load() async {
        resetError()
        isLoading = true

        do {
            currentMode = try await systemSettingsService.fetchMode()
        } catch {
            errorMessage = mapErrorMessage(error)
        }

        isLoading = false
    }

    func setMode(_ mode: SystemSettingsService.SystemMode) async {
        resetError()
        isLoading = true

        do {
            _ = try await systemSettingsService.setMode(mode)
            currentMode = mode
        } catch {
            errorMessage = mapErrorMessage(error)
        }

        isLoading = false
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
