//
//  LoginView.swift
//  EOC Check-In System
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

struct LoginView: View {

    @StateObject private var viewModel: LoginViewModel

    // MARK: - Init

    init(sessionManager: SessionManager) {
        _viewModel = StateObject(
            wrappedValue: LoginViewModel(sessionManager: sessionManager)
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {

            header

            form

            if let error = viewModel.errorMessage {
                errorView(message: error)
            }

            loginButton

            signupLink

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .brandedBackground()
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text("EOC Check-In")
                .font(.heading1)
                .fontWeight(.bold)

            Text("Personnel Tracking System")
                .font(.heading3)
                .foregroundColor(.textSecondary)

            Text("Sign in to continue")
                .font(.bodyRegular)
                .foregroundColor(.textSecondary)
                .padding(.top, 4)
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
        }
        .padding(.horizontal)
    }

    // MARK: - Login Button

    private var loginButton: some View {
        PrimaryButton(
            title: "Sign In",
            action: { Task { await viewModel.login() } },
            isLoading: viewModel.isLoading,
            isDisabled: !viewModel.canSubmit
        )
        .padding(.horizontal)
    }

    // MARK: - Signup Link

    private var signupLink: some View {
        NavigationLink {
            SignupView()
        } label: {
            Text("Need an account? Sign up")
                .font(.footnote)
        }
        .padding(.horizontal)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        Text(message)
            .foregroundColor(.appError)
            .multilineTextAlignment(.center)
    }
}
