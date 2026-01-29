//
//  ProfileCompletionView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

struct ProfileCompletionView: View {

    @ObservedObject private var viewModel: ProfileCompletionViewModel
    @EnvironmentObject private var sessionManager: SessionManager

    // MARK: - Init

    init(viewModel: ProfileCompletionViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {

            header

            form

            if let error = viewModel.errorMessage {
                errorView(message: error)
            }

            submitButton

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .onChange(of: viewModel.isProfileComplete) { isComplete in
            if isComplete {
                Task {
                    await reloadSession()
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text("Complete Your Profile")
                .font(.heading1)

            Text("Tell us a bit about yourself")
                .font(.heading4)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 32)
        .padding(.horizontal)
    }

    // MARK: - Form

    private var form: some View {
        VStack(spacing: 16) {

            VStack(alignment: .leading, spacing: 4) {
                Text("First Name *")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                TextField("First Name", text: $viewModel.firstName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Last Name *")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                TextField("Last Name", text: $viewModel.lastName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
            }

            Divider()
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 4) {
                Text("Phone Number (optional)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                TextField("Phone Number", text: $viewModel.phone)
                    .keyboardType(.phonePad)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Employer (optional)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                TextField("Employer", text: $viewModel.employer)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Credential Level (optional)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                TextField("Credential Level", text: $viewModel.credentialLevel)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        PrimaryButton(
            title: "Complete Profile",
            action: { Task { await viewModel.submitProfile() } },
            isLoading: viewModel.isLoading,
            isDisabled: !viewModel.canSubmit
        )
        .padding(.horizontal)
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        Text(message)
            .foregroundColor(.appError)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }

    // MARK: - Session Reload

    private func reloadSession() async {
        do {
            guard let authSession = try await BackendFactory.current.auth.currentSession() else {
                await MainActor.run {
                    viewModel.errorMessage = "No active session. Please log in again."
                }
                return
            }
            try await sessionManager.loadUserProfile(session: authSession)
        } catch {
            await MainActor.run {
                viewModel.errorMessage = "Profile created but failed to reload session. Please try logging in again."
            }
        }
    }
}
