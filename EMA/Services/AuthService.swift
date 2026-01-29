//
//  AuthService.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Handles authentication and authenticated user loading.
@MainActor
final class AuthService: Sendable {

    // MARK: - Dependencies

    private let backend: BackendProtocol
    private let usersRepository: UsersRepository

    // MARK: - Init

    init(
        backend: BackendProtocol = BackendFactory.current,
        usersRepository: UsersRepository = UsersRepository()
    ) {
        self.backend = backend
        self.usersRepository = usersRepository
    }

    // MARK: - Auth API

    /// Signs in an existing user and loads their User profile.
    func login(email: String, password: String) async throws -> User {
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)

        let session = try await backend.auth.signIn(
            email: emailTrimmed,
            password: password
        )

        let user = try await loadUserProfile(from: session)

        Logger.log(
            "User logged in",
            level: .info,
            category: "AuthService",
            metadata: ["userId": user.id.uuidString]
        )

        return user
    }

    /// Creates a new user account.
    func signUp(email: String, password: String) async throws -> AuthSession {
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)

        let result = try await backend.auth.signUp(
            email: emailTrimmed,
            password: password
        )

        Logger.log(
            "Signup succeeded",
            level: .info,
            category: "AuthService",
            metadata: ["email": emailTrimmed]
        )

        guard let session = result.session else {
            throw AppError.authentication(
                "Signup succeeded but no session is available yet. Please confirm your email, then sign in."
            )
        }

        return session
    }

    /// Signs out the current user.
    func signOut() async throws {
        try await backend.auth.signOut()

        Logger.log(
            "User signed out",
            level: .info,
            category: "AuthService"
        )
    }

    /// Loads the currently authenticated user's profile.
    func loadCurrentUser() async throws -> User {
        guard let session = try await backend.auth.currentSession() else {
            throw AppError.authentication("No active session")
        }
        return try await loadUserProfile(from: session)
    }

    // MARK: - Private Helpers

    private func loadUserProfile(from session: AuthSession) async throws -> User {
        let userId = session.userId
        return try await usersRepository.fetchUser(by: userId)
    }
}
