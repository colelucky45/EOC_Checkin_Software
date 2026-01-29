//
//  Logging.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//  Centralized logging utility for application events and errors.
//

import Foundation
import OSLog

/// Log severity levels used throughout the app.
enum LogLevel: String {
    case debug
    case info
    case warning
    case error
    case critical
}

/// Central logger for the application.
struct Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "EOCCheckIn"

    private static func osLogger(category: String) -> OSLog {
        OSLog(subsystem: subsystem, category: category)
    }

    /// Logs a general application message.
    static func log(
        _ message: String,
        level: LogLevel = .info,
        category: String = "Application",
        metadata: [String: Any]? = nil
    ) {
        let logger = osLogger(category: category)
        let formatted = format(message: message, metadata: metadata)

        switch level {
        case .debug:
            os_log(.debug, log: logger, "%{public}@", formatted)
        case .info:
            os_log(.info, log: logger, "%{public}@", formatted)
        case .warning:
            os_log(.default, log: logger, "%{public}@", formatted)
        case .error:
            os_log(.error, log: logger, "%{public}@", formatted)
        case .critical:
            os_log(.fault, log: logger, "%{public}@", formatted)
        }
    }

    /// Logs an AppError in a structured, consistent way.
    static func log(
        error: AppError,
        level: LogLevel = .error,
        category: String = "Error",
        context: String? = nil
    ) {
        var metadata: [String: Any] = [
            "error": error.localizedDescription,
            "userFacing": error.isUserFacing
        ]

        if let context {
            metadata["context"] = context
        }

        log(
            error.localizedDescription,
            level: level,
            category: category,
            metadata: metadata
        )
    }

    /// Logs an AppError to the remote logger (fire-and-forget).
    static func logToServerIfNeeded(
        error: AppError,
        level: LogLevel,
        category: String = "Error",
        context: String? = nil,
        details: [String: Any]? = nil
    ) {
        guard error.shouldLogToServer else { return }

        Task.detached(priority: .background) {
            var detailPayload = details ?? [:]
            detailPayload["category"] = category
            detailPayload["context"] = context ?? "n/a"
            detailPayload["userFacing"] = error.isUserFacing

            await BackendFactory.current.logger.logError(
                severity: level.rawValue,
                message: error.localizedDescription,
                details: detailPayload
            )
        }
    }

    /// Logs an unexpected raw Error.
    static func log(
        unexpected error: Error,
        category: String = "Unexpected"
    ) {
        log(
            error.localizedDescription,
            level: .critical,
            category: category,
            metadata: [
                "type": String(describing: type(of: error))
            ]
        )
    }

    // MARK: - Helpers

    private static func format(
        message: String,
        metadata: [String: Any]?
    ) -> String {
        guard let metadata, !metadata.isEmpty else {
            return message
        }

        let metaString = metadata
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ", ")

        return "\(message) | \(metaString)"
    }
}
