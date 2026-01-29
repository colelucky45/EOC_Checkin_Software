//
//  LoginViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/12/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class LoginViewModel: ObservableObject {

    // MARK: - Input State

    @Published var email: String = ""
    @Published var password: String = ""

    // MARK: - UI State

    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let sessionManager: SessionManager

    // MARK: - Init

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    // MARK: - Actions

    func login() async {
        guard !isLoading else { return }

        errorMessage = nil
        isLoading = true

        do {
            try await sessionManager.login(email: email, password: password)
            Haptics.success() // Success haptic on login
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error() // Error haptic on failure
        }

        isLoading = false
    }

    // MARK: - Validation

    var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !isLoading
    }
}
