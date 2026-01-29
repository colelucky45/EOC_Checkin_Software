//
//  CheckInRepository.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Handles all database operations for check-in / check-out records.
final class CheckInRepository: Sendable {

    private let database: DatabaseProviderProtocol
    private let table = "checkin_log"

    init(database: DatabaseProviderProtocol = BackendFactory.current.database) {
        self.database = database
    }

    // MARK: - Create Check-In

    func checkIn(
        userId: UUID,
        operationId: UUID,
        terminalId: String?,
        roleOnCheckin: String?,
        notes: String?,
        overnight: Bool = false
    ) async throws -> CheckIn {
        let payload = CheckInInsertPayload(
            userId: userId,
            operationId: operationId,
            checkinTime: Date(),
            terminalId: terminalId,
            roleOnCheckin: roleOnCheckin,
            notes: notes,
            overnight: overnight
        )

        return try await database.insert(payload, into: table)
    }

    // MARK: - Check Out

    func checkOut(
        checkInId: UUID,
        checkoutNote: String?
    ) async throws -> CheckIn {
        let payload = CheckOutUpdatePayload(
            checkoutTime: Date(),
            checkoutNote: checkoutNote
        )

        return try await database.update(payload, in: table, id: checkInId)
    }

    // MARK: - Fetch Active Check-Ins

    func fetchActiveCheckIns(operationId: UUID) async throws -> [CheckIn] {
        try await database.fetchMany(
            from: table,
            filters: [
                .equals("operation_id", operationId.uuidString),
                .isNull("checkout_time")
            ],
            order: nil,
            limit: nil
        )
    }

    // MARK: - Fetch All Check-Ins

    func fetchAllCheckIns() async throws -> [CheckIn] {
        try await database.fetchMany(
            from: table,
            filters: [],
            order: .desc("checkin_time"),
            limit: nil
        )
    }

    // MARK: - Fetch User History

    func fetchCheckIns(for userId: UUID) async throws -> [CheckIn] {
        try await database.fetchMany(
            from: table,
            filters: [.equals("user_id", userId.uuidString)],
            order: .desc("checkin_time"),
            limit: nil
        )
    }

    // MARK: - Fetch Current Check-In (If Any)

    func fetchCurrentCheckIn(for userId: UUID) async throws -> CheckIn? {
        let results: [CheckIn] = try await database.fetchMany(
            from: table,
            filters: [
                .equals("user_id", userId.uuidString),
                .isNull("checkout_time")
            ],
            order: nil,
            limit: 1
        )
        return results.first
    }

    // MARK: - Fetch Open Check-Ins

    func fetchOpenCheckIns(for userId: UUID) async throws -> [CheckIn] {
        try await database.fetchMany(
            from: table,
            filters: [
                .equals("user_id", userId.uuidString),
                .isNull("checkout_time")
            ],
            order: nil,
            limit: nil
        )
    }

    func fetchOpenCheckIns() async throws -> [CheckIn] {
        try await database.fetchMany(
            from: table,
            filters: [.isNull("checkout_time")],
            order: nil,
            limit: nil
        )
    }
}

// MARK: - Supporting Types

private struct CheckInInsertPayload: Encodable, Sendable {
    let userId: UUID
    let operationId: UUID
    let checkinTime: Date
    let terminalId: String?
    let roleOnCheckin: String?
    let notes: String?
    let overnight: Bool

    enum CodingKeys: String, CodingKey {
        case notes, overnight
        case userId = "user_id"
        case operationId = "operation_id"
        case checkinTime = "checkin_time"
        case terminalId = "terminal_id"
        case roleOnCheckin = "role_on_checkin"
    }
}

private struct CheckOutUpdatePayload: Encodable, Sendable {
    let checkoutTime: Date
    let checkoutNote: String?

    enum CodingKeys: String, CodingKey {
        case checkoutTime = "checkout_time"
        case checkoutNote = "checkout_note"
    }
}
