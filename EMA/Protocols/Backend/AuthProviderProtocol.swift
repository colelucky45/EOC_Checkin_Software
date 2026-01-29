//
//  AuthProviderProtocol.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Backend-agnostic authentication session
public struct AuthSession: Sendable, Equatable {
    public let userId: UUID
    public let email: String?
    public let accessToken: String
    public let refreshToken: String?
    public let expiresAt: Date?

    public init(
        userId: UUID,
        email: String?,
        accessToken: String,
        refreshToken: String? = nil,
        expiresAt: Date? = nil
    ) {
        self.userId = userId
        self.email = email
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    public var isExpired: Bool {
        guard let expiresAt else { return false }
        return Date() >= expiresAt
    }
}

/// Result of a signup operation
public struct SignUpResult: Sendable {
    public let session: AuthSession?
    public let needsEmailConfirmation: Bool

    public init(session: AuthSession?, needsEmailConfirmation: Bool) {
        self.session = session
        self.needsEmailConfirmation = needsEmailConfirmation
    }
}

/// Protocol for authentication providers (Firebase Auth, AWS Cognito, Azure AD, etc.)
public protocol AuthProviderProtocol: Sendable {
    func signIn(email: String, password: String) async throws -> AuthSession
    func signUp(email: String, password: String) async throws -> SignUpResult
    func signOut() async throws
    func currentSession() async throws -> AuthSession?
    func refreshSession() async throws -> AuthSession
}
