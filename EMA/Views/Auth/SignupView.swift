//
//  SignupView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

struct SignupView: View {

    @StateObject private var viewModel: SignupViewModel

    // MARK: - Init

    init() {
        _viewModel = StateObject(
            wrappedValue: SignupViewModel(authService: AuthService())
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {

            header

            form

            if let success = viewModel.successMessage {
                successView(message: success)
            }

            if let error = viewModel.errorMessage {
                errorView(message: error)
            }

            signupButton

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .brandedBackground()
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text("Visitor Signup")
                .font(.heading1)

            Text("Create an account to check in at the Emergency Operations Center")
                .font(.heading4)
                .foregroundColor(.textSecondary)
        }
        .padding(.top, 32)
        .padding(.horizontal)
    }

    // MARK: - Form

    private var form: some View {
        VStack(spacing: 16) {

            TextField("Email", text: $viewModel.email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)

            SecureField("Confirm Password", text: $viewModel.confirmPassword)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal)
    }

    // MARK: - Signup Button

    private var signupButton: some View {
        PrimaryButton(
            title: "Create Account",
            action: { Task { await viewModel.signUp() } },
            isLoading: viewModel.isLoading,
            isDisabled: !viewModel.canSubmit
        )
        .padding(.horizontal)
    }

    // MARK: - Success / Error Views

    private func successView(message: String) -> some View {
        Text(message)
            .foregroundColor(.appSuccess)
            .multilineTextAlignment(.center)
    }

    private func errorView(message: String) -> some View {
        Text(message)
            .foregroundColor(.appError)
            .multilineTextAlignment(.center)
    }
}
