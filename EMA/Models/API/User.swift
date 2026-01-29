//
//  User.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// API model representing a responder/admin/kiosk user in the EMACheckIn system.
/// Mirrors the `users` table in the database.
struct User: Identifiable, Codable, Equatable, Sendable {
    
    // MARK: - Core Fields (Schema-Aligned)
    let id: UUID
    let email: String?
    let phone: String?
    let employer: String?
    let role: String                 // ENUM-like but stored as text in DB
    let credentialLevel: String?
    let createdAt: Date
    let photoURL: String?
    let isActive: Bool
    let firstName: String
    let lastName: String
    
    // MARK: - Computed Properties
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var initials: String {
        let first = firstName.first.map(String.init) ?? ""
        let last = lastName.first.map(String.init) ?? ""
        return first + last
    }

    // MARK: - Coding Keys (Matches Database Exactly)
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case phone
        case employer
        case role
        case credentialLevel = "credential_level"
        case createdAt = "created_at"
        case photoURL = "photo_url"
        case isActive = "is_active"
        case firstName = "first_name"
        case lastName = "last_name"
    }
}
