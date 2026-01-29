//
//  KioskScanViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class KioskScanViewModel: ObservableObject {

    // MARK: - Published UI State

    @Published private(set) var isProcessing: Bool = false
    @Published private(set) var lastResult: Result<User, AppError>?
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?

    // MARK: - Dependencies

    private let kioskService: KioskService
    private let recoveryDelayNanoseconds: UInt64 = 1_500_000_000

    // MARK: - Init

    init(kioskService: KioskService) {
        self.kioskService = kioskService
    }

    // MARK: - Public Actions

    /// Called when a QR code is successfully scanned.
    func handleScan(qrToken: String) async {
        guard !isProcessing else { return }

        resetMessages()
        isProcessing = true

        let result = await kioskService.handleQrScan(rawScan: qrToken)
        handle(result: result)

        await recoverAfterDelay()
        isProcessing = false
    }

    /// Clears previous scan result (used between scans).
    func reset() {
        resetMessages()
        lastResult = nil
        isProcessing = false
    }

    // MARK: - Result Handling

    private func handle(result: Result<User, AppError>) {
        lastResult = result

        switch result {
        case .success(let user):
            successMessage = "Scan processed for \(user.firstName) \(user.lastName)."
            Haptics.success()
        case .failure(let error):
            errorMessage = error.userFacingMessage
            Haptics.error()
            Logger.log(
                error: error,
                level: error.logLevel,
                category: "KioskScan",
                context: "handle(result:)"
            )
            Logger.logToServerIfNeeded(
                error: error,
                level: error.logLevel,
                category: "KioskScan",
                context: "handle(result:)"
            )
        }
    }

    // MARK: - Helpers

    private func recoverAfterDelay() async {
        do {
            try await Task.sleep(nanoseconds: recoveryDelayNanoseconds)
        } catch { }

        resetMessages()
        lastResult = nil
    }

    private func resetMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
