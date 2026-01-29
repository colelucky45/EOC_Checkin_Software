//
//  ProfileCompletionViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ProfileCompletionViewModel: ObservableObject {

    // MARK: - Input State

    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var phone: String = ""
    @Published var employer: String = ""
    @Published var credentialLevel: String = ""

    // MARK: - UI State

    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isProfileComplete: Bool = false

    // MARK: - Dependencies

    private let usersRepository: UsersRepository
    private let userId: UUID
    private let userEmail: String

    // MARK: - Init

    init(
        userId: UUID,
        userEmail: String,
        usersRepository: UsersRepository = UsersRepository()
    ) {
        self.userId = userId
        self.userEmail = userEmail
        self.usersRepository = usersRepository
    }

    // MARK: - Actions

    func submitProfile() async {
        guard !isLoading else { return }

        errorMessage = nil
        isLoading = true

        do {
            _ = try await usersRepository.createResponderProfile(
                userId: userId,
                email: userEmail,
                firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                phone: phone.isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines),
                employer: employer.isEmpty ? nil : employer.trimmingCharacters(in: .whitespacesAndNewlines),
                credentialLevel: credentialLevel.isEmpty ? nil : credentialLevel.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            Logger.log(
                "Profile created successfully",
                level: .info,
                category: "ProfileCompletion",
                metadata: ["userId": userId.uuidString]
            )

            isProfileComplete = true

        } catch {
            errorMessage = error.localizedDescription

            Logger.log(
                error: .unexpected("Profile creation failed: \(error.localizedDescription)"),
                level: .error,
                category: "ProfileCompletion",
                context: "submitProfile"
            )
        }

        isLoading = false
    }

    // MARK: - Validation

    var canSubmit: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isLoading
    }
}
