//  SyncEngine.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//  Lightweight sync orchestration layer.
//  For now this provides a safe, testable, production-ready coordinator.
//

import Foundation

/// A sync event emitted by the SyncEngine that can be observed by ViewModels if needed.
struct SyncEvent: Sendable, Equatable {
    enum Kind: String, Sendable {
        case started
        case stepStarted
        case stepSucceeded
        case stepFailed
        case finished
        case cancelled
    }

    let kind: Kind
    let timestamp: Date
    let stepName: String?
    let message: String?

    init(kind: Kind, stepName: String? = nil, message: String? = nil, timestamp: Date = Date()) {
        self.kind = kind
        self.stepName = stepName
        self.message = message
        self.timestamp = timestamp
    }
}

/// A unit of work the SyncEngine can run.
/// This intentionally avoids tying to any storage implementation today.
struct SyncStep: Sendable {
    let name: String
    let run: @Sendable () async throws -> Void

    init(name: String, run: @escaping @Sendable () async throws -> Void) {
        self.name = name
        self.run = run
    }
}

/// Central sync coordinator.
/// Designed to be safe for production use now, and extensible for offline queue later.
actor SyncEngine {

    // MARK: - State

    private var steps: [SyncStep] = []
    private var syncTask: Task<Void, Never>?

    private(set) var isSyncing: Bool = false
    private(set) var lastSyncAt: Date?
    private(set) var lastError: AppError?

    // MARK: - Events

    private var eventContinuations: [UUID: AsyncStream<SyncEvent>.Continuation] = [:]

    /// Subscribe to sync events (optional).
    /// Callers should keep the stream alive for as long as they need updates.
    func events() -> AsyncStream<SyncEvent> {
        let id = UUID()
        return AsyncStream { continuation in
            eventContinuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContinuation(id) }
            }
        }
    }

    private func removeContinuation(_ id: UUID) {
        eventContinuations[id]?.finish()
        eventContinuations[id] = nil
    }

    private func emit(_ event: SyncEvent) {
        for (_, c) in eventContinuations {
            c.yield(event)
        }
    }

    // MARK: - Registration

    /// Registers a sync step. Steps run sequentially, in the order registered.
    /// Safe to call during app boot and whenever services initialize.
    func register(step: SyncStep) {
        steps.append(step)
        Logger.log("Registered sync step", level: .debug, category: "SyncEngine", metadata: ["name": step.name])
    }

    /// Removes all registered steps.
    /// Useful for tests or app role changes (e.g., switching environments/users).
    func resetSteps() {
        steps.removeAll()
        Logger.log("Reset sync steps", level: .info, category: "SyncEngine")
    }

    // MARK: - Control

    /// Starts a sync immediately (if not already syncing).
    /// If syncing is in progress, this is a no-op.
    func syncNow(reason: String? = nil) {
        guard syncTask == nil else {
            Logger.log("Sync requested but already in progress", level: .debug, category: "SyncEngine", metadata: ["reason": reason ?? "n/a"])
            return
        }

        syncTask = Task { [weak self] in
            guard let self else { return }
            await self.performSync(reason: reason)
        }
    }

    /// Cancels an in-progress sync, if any.
    func cancel() {
        syncTask?.cancel()
        syncTask = nil
        isSyncing = false
        emit(SyncEvent(kind: .cancelled))
        Logger.log("Sync cancelled", level: .warning, category: "SyncEngine")
    }

    // MARK: - Implementation

    private func performSync(reason: String?) async {
        isSyncing = true
        lastError = nil

        emit(SyncEvent(kind: .started, message: reason))
        Logger.log("Sync started", level: .info, category: "SyncEngine", metadata: ["reason": reason ?? "n/a", "stepCount": steps.count])

        defer {
            isSyncing = false
            syncTask = nil
        }

        // If there are no steps registered, we still mark a successful sync.
        guard !steps.isEmpty else {
            lastSyncAt = Date()
            emit(SyncEvent(kind: .finished, message: "No steps registered"))
            Logger.log("Sync finished (no steps)", level: .info, category: "SyncEngine")
            return
        }

        for step in steps {
            if Task.isCancelled {
                emit(SyncEvent(kind: .cancelled, stepName: step.name))
                Logger.log("Sync cancelled during step", level: .warning, category: "SyncEngine", metadata: ["step": step.name])
                return
            }

            emit(SyncEvent(kind: .stepStarted, stepName: step.name))
            Logger.log("Sync step started", level: .debug, category: "SyncEngine", metadata: ["step": step.name])

            do {
                try await step.run()
                emit(SyncEvent(kind: .stepSucceeded, stepName: step.name))
                Logger.log("Sync step succeeded", level: .info, category: "SyncEngine", metadata: ["step": step.name])
            } catch {
                let appError = (error as? AppError) ?? .unexpected(error.localizedDescription)
                lastError = appError

                emit(SyncEvent(kind: .stepFailed, stepName: step.name, message: appError.localizedDescription))
                Logger.log(error: appError, level: .error, category: "SyncEngine", context: "Step '\(step.name)' failed")

                // Production-safe default: fail fast.
                // When offline queue is implemented, we can switch to partial success + retry.
                emit(SyncEvent(kind: .finished, message: "Failed at step: \(step.name)"))
                return
            }
        }

        lastSyncAt = Date()
        emit(SyncEvent(kind: .finished))
        Logger.log("Sync finished successfully", level: .info, category: "SyncEngine", metadata: ["lastSyncAt": lastSyncAt?.description ?? "n/a"])
    }
}
