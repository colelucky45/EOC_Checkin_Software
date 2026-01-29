//
//  OperationDetailViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class OperationDetailViewModel: ObservableObject {

    // MARK: - Published UI State

    @Published private(set) var operation: Operation
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let operationsService: OperationsService

    // MARK: - Init

    init(
        operation: Operation,
        operationsService: OperationsService = OperationsService()
    ) {
        self.operation = operation
        self.operationsService = operationsService
    }

    // MARK: - Public API

    func refresh() async {
        resetError()
        isLoading = true

        do {
            operation = try await operationsService.fetch(by: operation.id)
        } catch {
            errorMessage = mapErrorMessage(error)
        }

        isLoading = false
    }

    func setActive(_ isActive: Bool) async {
        resetError()
        isLoading = true

        do {
            operation = try await operationsService.setActive(
                operationId: operation.id,
                isActive: isActive
            )
        } catch {
            errorMessage = mapErrorMessage(error)
        }

        isLoading = false
    }

    func setVisible(_ isVisible: Bool) async {
        resetError()
        isLoading = true

        do {
            operation = try await operationsService.setVisible(
                operationId: operation.id,
                isVisible: isVisible
            )
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
