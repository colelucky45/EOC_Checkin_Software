//
//  UsersRepository.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Handles all database operations for User records.
final class UsersRepository: Sendable {

    private let database: DatabaseProviderProtocol
    private let table = "users"

    init(database: DatabaseProviderProtocol = BackendFactory.current.database) {
        self.database = database
    }

    // MARK: - Fetch All Users

    func fetchAllUsers() async throws -> [User] {
        try await database.fetchMany(
            from: table,
            filters: [],
            order: .desc("last_name"),
            limit: nil
        )
    }

    // MARK: - Fetch User by ID

    func fetchUser(by id: UUID) async throws -> User {
        try await database.fetchOne(from: table, id: id)
    }

    // MARK: - Search by Name

    func searchUsers(byName query: String) async throws -> [User] {
        // Note: Complex OR queries may need custom implementation in your backend
        // This is a simplified version that searches first_name only
        try await database.fetchMany(
            from: table,
            filters: [.ilike("first_name", "%\(query)%")],
            order: .asc("last_name"),
            limit: nil
        )
    }

    // MARK: - Create User (Admin feature)

    func createUser(_ user: User) async throws -> User {
        try await database.insert(user, into: table)
    }

    // MARK: - Create Responder Profile (Self-Service Onboarding)

    func createResponderProfile(
        userId: UUID,
        email: String,
        firstName: String,
        lastName: String,
        phone: String?,
        employer: String?,
        credentialLevel: String?
    ) async throws -> User {
        let payload = UserProfilePayload(
            id: userId,
            email: email,
            firstName: firstName,
            lastName: lastName,
            phone: phone,
            employer: employer,
            credentialLevel: credentialLevel,
            role: "responder",
            isActive: true
        )

        return try await database.insert(payload, into: table)
    }

    // MARK: - Update User

    func updateUser(_ user: User) async throws -> User {
        try await database.update(user, in: table, id: user.id)
    }

    // MARK: - Update Profile (Self-Service)

    func updateProfile(
        userId: UUID,
        firstName: String,
        lastName: String,
        email: String?,
        phone: String?,
        employer: String?,
        credentialLevel: String?
    ) async throws -> User {
        let payload = ProfileUpdatePayload(
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            employer: employer,
            credentialLevel: credentialLevel
        )

        return try await database.update(payload, in: table, id: userId)
    }

    // MARK: - Toggle Active State

    func setUserActive(_ id: UUID, isActive: Bool) async throws -> User {
        let payload = IsActivePayload(isActive: isActive)
        return try await database.update(payload, in: table, id: id)
    }

    // MARK: - Delete User

    func deleteUser(userId: UUID) async throws {
        try await database.delete(from: table, id: userId)
    }

    // MARK: - Fetch User for Auth (email-based login)

    func fetchUser(byEmail email: String) async throws -> User {
        try await database.fetchOne(from: table, filter: .equals("email", email))
    }
}

// MARK: - Supporting Types

private struct UserProfilePayload: Encodable, Sendable {
    let id: UUID
    let email: String
    let firstName: String
    let lastName: String
    let phone: String?
    let employer: String?
    let credentialLevel: String?
    let role: String
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, email, phone, employer, role
        case firstName = "first_name"
        case lastName = "last_name"
        case credentialLevel = "credential_level"
        case isActive = "is_active"
    }
}

private struct ProfileUpdatePayload: Encodable, Sendable {
    let firstName: String
    let lastName: String
    let email: String?
    let phone: String?
    let employer: String?
    let credentialLevel: String?

    enum CodingKeys: String, CodingKey {
        case email, phone, employer
        case firstName = "first_name"
        case lastName = "last_name"
        case credentialLevel = "credential_level"
    }
}

private struct IsActivePayload: Encodable, Sendable {
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case isActive = "is_active"
    }
}
