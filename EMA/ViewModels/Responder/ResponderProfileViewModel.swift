//
//  ResponderProfileViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ResponderProfileViewModel: ObservableObject {

    // MARK: - Published UI State

    @Published private(set) var user: User?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successMessage: String?

    // Edit mode
    @Published var isEditing: Bool = false

    // Editable fields
    @Published var editFirstName: String = ""
    @Published var editLastName: String = ""
    @Published var editEmail: String = ""
    @Published var editPhone: String = ""
    @Published var editEmployer: String = ""
    @Published var editPosition: String = ""

    // MARK: - Dependencies

    private let authService: AuthService
    private let usersRepository: UsersRepository
    private let session: SessionManager

    // MARK: - Init

    init(
        authService: AuthService? = nil,
        usersRepository: UsersRepository? = nil,
        session: SessionManager
    ) {
        self.authService = authService ?? AuthService()
        self.usersRepository = usersRepository ?? UsersRepository()
        self.session = session
    }

    // MARK: - Public API

    func load() async {
        resetError()
        isLoading = true

        do {
            user = try await authService.loadCurrentUser()
            populateEditFields()
        } catch {
            errorMessage = mapErrorMessage(error)
        }

        isLoading = false
    }

    func startEditing() {
        populateEditFields()
        isEditing = true
        resetMessages()
    }

    func cancelEditing() {
        isEditing = false
        populateEditFields() // Reset to original values
        resetMessages()
    }

    func saveProfile() async {
        guard let userId = user?.id else { return }

        // Validate required fields
        guard !editFirstName.trimmingCharacters(in: .whitespaces).isEmpty,
              !editLastName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "First name and last name are required"
            return
        }

        resetMessages()
        isLoading = true

        do {
            let updatedUser = try await usersRepository.updateProfile(
                userId: userId,
                firstName: editFirstName.trimmingCharacters(in: .whitespaces),
                lastName: editLastName.trimmingCharacters(in: .whitespaces),
                email: editEmail.isEmpty ? nil : editEmail.trimmingCharacters(in: .whitespaces),
                phone: editPhone.isEmpty ? nil : editPhone.trimmingCharacters(in: .whitespaces),
                employer: editEmployer.isEmpty ? nil : editEmployer.trimmingCharacters(in: .whitespaces),
                credentialLevel: editPosition.isEmpty ? nil : editPosition.trimmingCharacters(in: .whitespaces)
            )

            // Update local state
            user = updatedUser

            // Update SessionManager so all other views see the updated user
            session.updateCurrentUser(updatedUser)

            isEditing = false
            successMessage = "Profile updated successfully"

            // Clear success message after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                successMessage = nil
            }
        } catch {
            errorMessage = mapErrorMessage(error)
        }

        isLoading = false
    }

    // MARK: - Helpers

    private func populateEditFields() {
        guard let user = user else { return }
        editFirstName = user.firstName
        editLastName = user.lastName
        editEmail = user.email ?? ""
        editPhone = user.phone ?? ""
        editEmployer = user.employer ?? ""
        editPosition = user.credentialLevel ?? ""
    }

    private func resetError() {
        errorMessage = nil
    }

    private func resetMessages() {
        errorMessage = nil
        successMessage = nil
    }

    private func mapErrorMessage(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }
        return error.localizedDescription
    }
}
