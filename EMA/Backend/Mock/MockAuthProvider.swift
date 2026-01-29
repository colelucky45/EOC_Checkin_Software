//
//  MockAuthProvider.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Mock auth provider for testing
final class MockAuthProvider: AuthProviderProtocol, @unchecked Sendable {
    private var mockSession: AuthSession?

    func signIn(email: String, password: String) async throws -> AuthSession {
        let session = AuthSession(
            userId: UUID(),
            email: email,
            accessToken: "mock-token-\(UUID().uuidString)",
            refreshToken: "mock-refresh",
            expiresAt: Date().addingTimeInterval(3600)
        )
        mockSession = session
        return session
    }

    func signUp(email: String, password: String) async throws -> SignUpResult {
        SignUpResult(session: nil, needsEmailConfirmation: true)
    }

    func signOut() async throws {
        mockSession = nil
    }

    func currentSession() async throws -> AuthSession? {
        mockSession
    }

    func refreshSession() async throws -> AuthSession {
        guard let session = mockSession else {
            throw AppError.authentication("No session to refresh")
        }
        return session
    }
}
