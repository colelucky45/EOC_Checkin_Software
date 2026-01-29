//
//  WriteQueue.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Thread-safe queue for offline write operations.
/// Stores pending check-ins and meals to be synced when online.
actor WriteQueue {

    // MARK: - Singleton

    static let shared = WriteQueue()

    private init() {}

    // MARK: - Constants

    private let maxRetries = 3
    private let queueFileName = "write_queue.json"

    // MARK: - File Management

    private var queueFileURL: URL {
        get throws {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            guard let documentsDirectory = paths.first else {
                throw AppError.unexpected("Documents directory not available")
            }
            let queueDir = documentsDirectory.appendingPathComponent("WriteQueue", isDirectory: true)

            // Create directory if it doesn't exist
            if !FileManager.default.fileExists(atPath: queueDir.path) {
                try FileManager.default.createDirectory(at: queueDir, withIntermediateDirectories: true)
            }

            return queueDir.appendingPathComponent(queueFileName)
        }
    }

    // MARK: - Public API

    /// Adds a write operation to the queue.
    func enqueue(_ write: QueuedWrite) async throws {
        var queue = try await loadQueue()
        queue.append(write)
        try await saveQueue(queue)

        Logger.log(
            "Write queued",
            level: .info,
            category: "WriteQueue",
            metadata: [
                "id": write.id.uuidString,
                "type": write.type.rawValue,
                "queueSize": queue.count
            ]
        )
    }

    /// Returns all pending writes (status = .pending) that are ready to retry.
    /// Respects exponential backoff based on retry count.
    func pendingWrites() async throws -> [QueuedWrite] {
        let queue = try await loadQueue()
        return queue.filter { $0.status == .pending && $0.canRetryNow() }
    }

    /// Returns all writes in the queue (any status).
    func allWrites() async throws -> [QueuedWrite] {
        try await loadQueue()
    }

    /// Marks a write as syncing and updates last attempt time.
    func markSyncing(_ id: UUID) async throws {
        var queue = try await loadQueue()

        guard let index = queue.firstIndex(where: { $0.id == id }) else {
            return
        }

        queue[index].status = .syncing
        queue[index].lastAttemptTime = Date()
        try await saveQueue(queue)
    }

    /// Removes a write from the queue after successful sync.
    func remove(_ id: UUID) async throws {
        var queue = try await loadQueue()
        queue.removeAll { $0.id == id }
        try await saveQueue(queue)

        Logger.log(
            "Write removed from queue",
            level: .info,
            category: "WriteQueue",
            metadata: ["id": id.uuidString, "queueSize": queue.count]
        )
    }

    /// Marks a write as failed and increments retry count.
    /// Uses exponential backoff for retries (2s, 4s, 8s).
    func markFailed(_ id: UUID, error: Error) async throws {
        var queue = try await loadQueue()

        guard let index = queue.firstIndex(where: { $0.id == id }) else {
            return
        }

        queue[index].retryCount += 1
        queue[index].status = (queue[index].retryCount >= maxRetries) ? .failed : .pending
        queue[index].lastAttemptTime = Date()

        let backoffSeconds = queue[index].backoffDelay()

        try await saveQueue(queue)

        Logger.log(
            error: .unexpected("Write failed: \(error.localizedDescription)"),
            level: .error,
            category: "WriteQueue",
            context: "Write ID: \(id.uuidString), Retry: \(queue[index].retryCount)/\(maxRetries), Next retry in: \(Int(backoffSeconds))s"
        )
    }

    /// Clears all writes from the queue. Use with caution.
    func clearAll() async throws {
        try await saveQueue([])

        Logger.log(
            "Write queue cleared",
            level: .warning,
            category: "WriteQueue"
        )
    }

    /// Returns queue statistics for debugging.
    func stats() async throws -> [String: Any] {
        let queue = try await loadQueue()

        let pending = queue.filter { $0.status == .pending }.count
        let syncing = queue.filter { $0.status == .syncing }.count
        let failed = queue.filter { $0.status == .failed }.count

        return [
            "total": queue.count,
            "pending": pending,
            "syncing": syncing,
            "failed": failed,
            "oldestWrite": queue.first?.timestamp.description ?? "none"
        ]
    }

    // MARK: - Private Helpers

    private func loadQueue() async throws -> [QueuedWrite] {
        let url = try queueFileURL

        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            return try decoder.decode([QueuedWrite].self, from: data)
        } catch {
            Logger.log(
                error: .unexpected("Queue decode failed: \(error.localizedDescription)"),
                level: .error,
                category: "WriteQueue",
                context: "loadQueue"
            )
            return []
        }
    }

    private func saveQueue(_ queue: [QueuedWrite]) async throws {
        let url = try queueFileURL
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(queue)
        try data.write(to: url, options: .atomic)
    }

    private func updateStatus(_ id: UUID, to status: QueuedWrite.Status) async throws {
        var queue = try await loadQueue()

        guard let index = queue.firstIndex(where: { $0.id == id }) else {
            return
        }

        queue[index].status = status
        try await saveQueue(queue)
    }
}
