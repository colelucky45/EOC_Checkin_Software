//
//  AdminQRViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import Combine

/// ViewModel for admin QR code generation.
/// Allows admins to generate and display QR codes for administrative purposes.
@MainActor
final class AdminQRViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var qrValue: String?
    @Published private(set) var adminName: String = ""
    @Published private(set) var expiresAt: Date?
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
        await generateToken(forceRefresh: false)
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
            Logger.log(
                "Failed to load operations for QR generation: \(error.localizedDescription)",
                level: .warning,
                category: "AdminQRViewModel"
            )
        }
    }

    private func generateToken(forceRefresh: Bool) async {
        isLoading = true
        errorMessage = nil

        do {
            let user = try await authService.loadCurrentUser()
            adminName = user.fullName

            // Require operation selection if there are active operations
            guard activeTodayOperations.isEmpty || session.selectedOperation != nil else {
                qrValue = nil
                expiresAt = nil
                errorMessage = "Please select an operation before generating QR code"
                isLoading = false
                return
            }

            let tokenResult = await qrService.fetchOrCreateToken(
                for: user,
                operationId: session.selectedOperation?.id,
                forceRefresh: forceRefresh
            )

            switch tokenResult {
            case .success(let token):
                qrValue = token.token
                expiresAt = token.expiresAt
                errorMessage = nil
            case .failure(let error):
                errorMessage = error.userFacingMessage
                qrValue = nil
            }
        } catch {
            let appError = error as? AppError ?? AppError.unexpected(error.localizedDescription)
            errorMessage = appError.userFacingMessage
            qrValue = nil
        }

        isLoading = false
    }

    func refresh() async {
        await generateToken(forceRefresh: true)
    }
}
