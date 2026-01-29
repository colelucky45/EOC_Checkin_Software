//
//  QueuedWrite.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Represents a pending write operation that will be synced when online.
/// Used for offline kiosk check-ins and meal logging.
struct QueuedWrite: Identifiable, Codable, Equatable, Sendable {

    let id: UUID
    let type: WriteType
    let payload: Data
    let timestamp: Date
    var retryCount: Int
    var status: Status
    var lastAttemptTime: Date?

    enum WriteType: String, Codable, Sendable {
        case checkIn
        case checkOut
        case meal
    }

    enum Status: String, Codable, Sendable {
        case pending
        case syncing
        case failed
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case payload
        case timestamp
        case retryCount = "retry_count"
        case status
        case lastAttemptTime = "last_attempt_time"
    }

    init(
        id: UUID = UUID(),
        type: WriteType,
        payload: Data,
        timestamp: Date = Date(),
        retryCount: Int = 0,
        status: Status = .pending,
        lastAttemptTime: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.payload = payload
        self.timestamp = timestamp
        self.retryCount = retryCount
        self.status = status
        self.lastAttemptTime = lastAttemptTime
    }

    /// Calculates exponential backoff delay in seconds based on retry count.
    /// Returns: 2^retryCount seconds (2s, 4s, 8s, etc.)
    func backoffDelay() -> TimeInterval {
        return pow(2.0, Double(retryCount))
    }

    /// Returns true if enough time has passed since last attempt to retry.
    func canRetryNow() -> Bool {
        guard let lastAttempt = lastAttemptTime else {
            return true // Never attempted, can retry immediately
        }

        let backoff = backoffDelay()
        let timeSinceLastAttempt = Date().timeIntervalSince(lastAttempt)
        return timeSinceLastAttempt >= backoff
    }
}

// MARK: - Payload Helpers

extension QueuedWrite {

    /// Creates a queued write for a check-in operation.
    static func checkIn(
        userId: UUID,
        operationId: UUID,
        terminalId: String?,
        roleOnCheckin: String?,
        notes: String?,
        overnight: Bool = false
    ) throws -> QueuedWrite {
        let checkIn = CheckIn(
            id: UUID(),
            userId: userId,
            operationId: operationId,
            checkinTime: Date(),
            checkoutTime: nil,
            terminalId: terminalId,
            notes: notes,
            overnight: overnight,
            roleOnCheckin: roleOnCheckin,
            checkoutNote: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let payload = try encoder.encode(checkIn)

        return QueuedWrite(type: .checkIn, payload: payload)
    }

    /// Creates a queued write for a check-out operation.
    static func checkOut(
        checkInId: UUID,
        checkoutNote: String?
    ) throws -> QueuedWrite {
        let checkOutData = CheckOutPayload(
            checkInId: checkInId,
            checkoutNote: checkoutNote
        )

        let encoder = JSONEncoder()
        let payload = try encoder.encode(checkOutData)

        return QueuedWrite(type: .checkOut, payload: payload)
    }

    /// Creates a queued write for a meal operation.
    static func meal(
        mealType: String,
        quantity: Int,
        servedAt: Date,
        terminalId: String?,
        notes: String?,
        operationId: UUID?,
        userId: UUID?
    ) throws -> QueuedWrite {
        let meal = MealLog(
            id: UUID(),
            mealType: mealType,
            quantity: quantity,
            servedAt: servedAt,
            terminalId: terminalId,
            notes: notes,
            operationId: operationId,
            userId: userId
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let payload = try encoder.encode(meal)

        return QueuedWrite(type: .meal, payload: payload)
    }

    /// Decodes the payload as a CheckIn.
    func asCheckIn() throws -> CheckIn {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CheckIn.self, from: payload)
    }

    /// Decodes the payload as a CheckOutPayload.
    func asCheckOut() throws -> CheckOutPayload {
        let decoder = JSONDecoder()
        return try decoder.decode(CheckOutPayload.self, from: payload)
    }

    /// Decodes the payload as a MealLog.
    func asMealLog() throws -> MealLog {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MealLog.self, from: payload)
    }
}

// MARK: - Supporting Types

struct CheckOutPayload: Codable, Sendable {
    let checkInId: UUID
    let checkoutNote: String?

    enum CodingKeys: String, CodingKey {
        case checkInId = "check_in_id"
        case checkoutNote = "checkout_note"
    }
}
