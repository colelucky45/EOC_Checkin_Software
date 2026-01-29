//
//  LocalUser.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Local/offline representation of a user (responder/admin/kiosk).
/// Used for caching user profiles and supporting offline kiosk operation.
struct LocalUser: Identifiable, Codable, Equatable, Sendable {
    
    let id: UUID
    let email: String?
    let phone: String?
    let employer: String?
    let role: String
    let credentialLevel: String?
    let createdAt: Date
    let photoURL: String?
    let isActive: Bool
    let firstName: String
    let lastName: String
    
    /// Timestamp of last successful sync for this user.
    let syncedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case phone
        case employer
        case role
        case credentialLevel = "credential_level"
        case createdAt       = "created_at"
        case photoURL        = "photo_url"
        case isActive        = "is_active"
        case firstName       = "first_name"
        case lastName        = "last_name"
        case syncedAt        = "synced_at"
    }
    
    // MARK: - Computed
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

extension LocalUser {
    
    /// Creates a local representation from the API model.
    init(from api: User, syncedAt: Date? = Date()) {
        self.id = api.id
        self.email = api.email
        self.phone = api.phone
        self.employer = api.employer
        self.role = api.role
        self.credentialLevel = api.credentialLevel
        self.createdAt = api.createdAt
        self.photoURL = api.photoURL
        self.isActive = api.isActive
        self.firstName = api.firstName
        self.lastName = api.lastName
        self.syncedAt = syncedAt
    }
    
    /// Converts back to API model.
    func toAPIModel() -> User {
        User(
            id: id,
            email: email,
            phone: phone,
            employer: employer,
            role: role,
            credentialLevel: credentialLevel,
            createdAt: createdAt,
            photoURL: photoURL,
            isActive: isActive,
            firstName: firstName,
            lastName: lastName
        )
    }
}

