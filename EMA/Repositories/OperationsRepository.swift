//
//  OperationsRepository.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Handles all database operations for Operation records.
final class OperationsRepository: Sendable {

    private let database: DatabaseProviderProtocol
    private let table = "operations"

    init(database: DatabaseProviderProtocol = BackendFactory.current.database) {
        self.database = database
    }

    // MARK: - Fetch All

    func fetchAllOperations() async throws -> [Operation] {
        try await database.fetchMany(
            from: table,
            filters: [],
            order: .desc("created_at"),
            limit: nil
        )
    }

    // MARK: - Fetch by ID

    func fetchOperation(by id: UUID) async throws -> Operation {
        try await database.fetchOne(from: table, id: id)
    }

    // MARK: - Fetch Active / Visible

    func fetchActiveOperations() async throws -> [Operation] {
        try await database.fetchMany(
            from: table,
            filters: [.equals("is_active", true)],
            order: .desc("created_at"),
            limit: nil
        )
    }

    func fetchVisibleOperations() async throws -> [Operation] {
        try await database.fetchMany(
            from: table,
            filters: [.equals("is_visible", true)],
            order: .desc("created_at"),
            limit: nil
        )
    }

    func fetchActiveVisibleOperations() async throws -> [Operation] {
        try await database.fetchMany(
            from: table,
            filters: [
                .equals("is_active", true),
                .equals("is_visible", true)
            ],
            order: .desc("created_at"),
            limit: nil
        )
    }

    // MARK: - Search

    func searchOperations(byName query: String) async throws -> [Operation] {
        try await database.fetchMany(
            from: table,
            filters: [.ilike("name", "%\(query)%")],
            order: .desc("created_at"),
            limit: nil
        )
    }

    // MARK: - Create / Update (Admin)

    func createOperation(_ operation: Operation) async throws -> Operation {
        try await database.insert(operation, into: table)
    }

    func updateOperation(_ operation: Operation) async throws -> Operation {
        try await database.update(operation, in: table, id: operation.id)
    }

    // MARK: - Toggle Flags (Admin)

    func setOperationActive(_ id: UUID, isActive: Bool) async throws -> Operation {
        let payload = IsActivePayload(isActive: isActive)
        return try await database.update(payload, in: table, id: id)
    }

    func setOperationVisible(_ id: UUID, isVisible: Bool) async throws -> Operation {
        let payload = IsVisiblePayload(isVisible: isVisible)
        return try await database.update(payload, in: table, id: id)
    }

    // MARK: - Delete (Optional Admin)

    func deleteOperation(_ id: UUID) async throws -> Operation {
        try await database.delete(from: table, id: id)
    }
}

// MARK: - Supporting Types

private struct IsActivePayload: Encodable, Sendable {
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case isActive = "is_active"
    }
}

private struct IsVisiblePayload: Encodable, Sendable {
    let isVisible: Bool

    enum CodingKeys: String, CodingKey {
        case isVisible = "is_visible"
    }
}
