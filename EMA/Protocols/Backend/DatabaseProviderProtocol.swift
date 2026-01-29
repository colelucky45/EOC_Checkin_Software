//
//  DatabaseProviderProtocol.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Query filter for database operations
public struct QueryFilter: @unchecked Sendable {
    public enum Operator: String, Sendable {
        case equals = "eq"
        case notEquals = "neq"
        case greaterThan = "gt"
        case lessThan = "lt"
        case greaterThanOrEquals = "gte"
        case lessThanOrEquals = "lte"
        case like = "like"
        case ilike = "ilike"
        case isNull = "is_null"
    }

    public let column: String
    public let op: Operator
    public let value: Any?

    public init(column: String, op: Operator, value: Any? = nil) {
        self.column = column
        self.op = op
        self.value = value
    }

    public static func equals(_ column: String, _ value: Any?) -> QueryFilter {
        QueryFilter(column: column, op: .equals, value: value)
    }

    public static func isNull(_ column: String) -> QueryFilter {
        QueryFilter(column: column, op: .isNull, value: nil)
    }

    public static func ilike(_ column: String, _ pattern: String) -> QueryFilter {
        QueryFilter(column: column, op: .ilike, value: pattern)
    }
}

/// Sort order for queries
public struct QueryOrder: Sendable {
    public let column: String
    public let ascending: Bool

    public init(column: String, ascending: Bool = true) {
        self.column = column
        self.ascending = ascending
    }

    public static func asc(_ column: String) -> QueryOrder {
        QueryOrder(column: column, ascending: true)
    }

    public static func desc(_ column: String) -> QueryOrder {
        QueryOrder(column: column, ascending: false)
    }
}

/// Protocol for database operations (Firestore, DynamoDB, Cosmos DB, REST API, etc.)
public protocol DatabaseProviderProtocol: Sendable {
    func fetchOne<T: Decodable>(from table: String, id: UUID) async throws -> T
    func fetchOne<T: Decodable>(from table: String, filter: QueryFilter) async throws -> T
    func fetchMany<T: Decodable>(from table: String, filters: [QueryFilter], order: QueryOrder?, limit: Int?) async throws -> [T]
    func insert<T: Encodable, R: Decodable>(_ record: T, into table: String) async throws -> R
    func update<T: Encodable, R: Decodable>(_ record: T, in table: String, id: UUID) async throws -> R
    func update<T: Encodable, R: Decodable>(_ record: T, in table: String, filter: QueryFilter) async throws -> R
    func delete<R: Decodable>(from table: String, id: UUID) async throws -> R
    func delete(from table: String, id: UUID) async throws
}

public extension DatabaseProviderProtocol {
    func fetchAll<T: Decodable>(from table: String) async throws -> [T] {
        try await fetchMany(from: table, filters: [], order: nil, limit: nil)
    }
}
