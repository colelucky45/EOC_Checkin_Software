//
//  ResponderQRViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ResponderQRViewModel: ObservableObject {

    // MARK: - Published UI State

    @Published private(set) var qrValue: String?
    @Published private(set) var expiresAt: Date?
    @Published private(set) var responderName: String = ""
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // Operation selection
    @Published private(set) var activeTodayOperations: [Operation] = []

    // MARK: - Dependencies

    private let qrService: QRService
    private let authService: AuthService
    private let operationsService: OperationsService
    private let session: SessionManager

    // MARK: - Init

    init(
        qrService: QRService? = nil,
        authService: AuthService? = nil,
        operationsService: OperationsService? = nil,
        session: SessionManager
    ) {
        self.qrService = qrService ?? QRService()
        self.authService = authService ?? AuthService()
        self.operationsService = operationsService ?? OperationsService()
        self.session = session
    }

    // MARK: - Public API

    func load() async {
        await loadOperations()
        await fetchToken(forceRefresh: false)
    }

    func refresh() async {
        await fetchToken(forceRefresh: true)
    }

    // MARK: - Helpers

    private func loadOperations() async {
        do {
            activeTodayOperations = try await operationsService.fetchActiveTodayVisible()

            // Auto-select if only one operation
            if activeTodayOperations.count == 1 {
                session.selectedOperation = activeTodayOperations.first
            }
        } catch {
            // Don't block QR generation on operation fetch failure
            // User can still generate QR without operation if needed
            Logger.log(
                "Failed to load operations for QR generation: \(error.localizedDescription)",
                level: .warning,
                category: "ResponderQRViewModel"
            )
        }
    }

    private func fetchToken(forceRefresh: Bool) async {
        resetError()
        isLoading = true

        do {
            let user = try await authService.loadCurrentUser()
            responderName = user.fullName

            // Require operation selection if there are active operations
            guard activeTodayOperations.isEmpty || session.selectedOperation != nil else {
                qrValue = nil
                expiresAt = nil
                errorMessage = "Please select an operation before generating QR code"
                isLoading = false
                return
            }

            let result = await qrService.fetchOrCreateToken(
                for: user,
                operationId: session.selectedOperation?.id,
                forceRefresh: forceRefresh
            )

            switch result {
            case .success(let token):
                qrValue = token.token
                expiresAt = token.expiresAt
            case .failure(let error):
                qrValue = nil
                expiresAt = nil
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = mapErrorMessage(error)
        }

        isLoading = false
    }

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
