//
//  MockDatabaseProvider.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Mock database provider for testing
final class MockDatabaseProvider: DatabaseProviderProtocol, @unchecked Sendable {

    func fetchOne<T: Decodable>(from table: String, id: UUID) async throws -> T {
        throw AppError.notFound("Mock: Record not found in \(table)")
    }

    func fetchOne<T: Decodable>(from table: String, filter: QueryFilter) async throws -> T {
        throw AppError.notFound("Mock: Record not found in \(table)")
    }

    func fetchMany<T: Decodable>(
        from table: String,
        filters: [QueryFilter],
        order: QueryOrder?,
        limit: Int?
    ) async throws -> [T] {
        return []
    }

    func insert<T: Encodable, R: Decodable>(_ record: T, into table: String) async throws -> R {
        let data = try JSONEncoder().encode(record)
        return try JSONDecoder().decode(R.self, from: data)
    }

    func update<T: Encodable, R: Decodable>(_ record: T, in table: String, id: UUID) async throws -> R {
        let data = try JSONEncoder().encode(record)
        return try JSONDecoder().decode(R.self, from: data)
    }

    func update<T: Encodable, R: Decodable>(_ record: T, in table: String, filter: QueryFilter) async throws -> R {
        let data = try JSONEncoder().encode(record)
        return try JSONDecoder().decode(R.self, from: data)
    }

    func delete<R: Decodable>(from table: String, id: UUID) async throws -> R {
        throw AppError.notFound("Mock: Cannot delete from \(table)")
    }

    func delete(from table: String, id: UUID) async throws {
        // No-op
    }
}
