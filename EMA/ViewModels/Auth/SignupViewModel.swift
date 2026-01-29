//
//  SignupViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/12/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SignupViewModel: ObservableObject {

    // MARK: - Input State

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""

    // MARK: - UI State

    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?

    // MARK: - Dependencies

    private let authService: AuthService

    // MARK: - Init

    init(authService: AuthService) {
        self.authService = authService
    }

    // MARK: - Actions

    func signUp() async {
        guard !isLoading else { return }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        errorMessage = nil
        successMessage = nil
        isLoading = true

        do {
            _ = try await authService.signUp(
                email: email,
                password: password
            )

            successMessage =
                "Account created successfully. Please check your email to confirm your account before signing in."

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Validation

    var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        !isLoading
    }
}
