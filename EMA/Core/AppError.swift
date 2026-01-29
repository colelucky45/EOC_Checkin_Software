//
//  AppError.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//  Centralized application error definition.
//  Used across repositories, services, and view models.

import Foundation

/// A strongly-typed application error used throughout the app.
/// This is the single error surface exposed beyond the service layer.
enum AppError: Error, Identifiable, Equatable {
    case network(NetworkFailure)
    case authentication(String)
    case authorization(String)
    case validation(String)
    case notFound(String)
    case conflict(String)
    case persistence(String)
    case decoding(String)
    case unexpected(String)

    var id: String {
        localizedDescription
    }

    /// Human-readable message safe for UI display.
    var localizedDescription: String {
        switch self {
        case .network(let failure):
            return failure.localizedDescription
        case .authentication(let message),
             .authorization(let message),
             .validation(let message),
             .notFound(let message),
             .conflict(let message),
             .persistence(let message),
             .decoding(let message),
             .unexpected(let message):
            return message
        }
    }

    /// Indicates whether the error should be surfaced to the user.
    var isUserFacing: Bool {
        switch self {
        case .network,
             .authentication,
             .authorization,
             .validation,
             .notFound,
             .conflict:
            return true
        case .persistence,
             .decoding,
             .unexpected:
            return false
        }
    }

    /// User-safe message for kiosk and other UI surfaces.
    var userFacingMessage: String {
        isUserFacing ? localizedDescription : "Something went wrong. Please try again."
    }

    /// Returns true if this is a notFound error.
    var isNotFound: Bool {
        if case .notFound = self {
            return true
        }
        return false
    }

    /// Indicates whether this error should be persisted to server logs.
    var shouldLogToServer: Bool {
        switch self {
        case .validation, .conflict, .notFound, .network:
            return false
        case .authentication, .authorization, .persistence, .decoding, .unexpected:
            return true
        }
    }

    /// Recommended log severity for this error.
    var logLevel: LogLevel {
        switch self {
        case .validation, .conflict, .notFound:
            return .info
        case .network:
            return .warning
        case .authentication, .authorization, .persistence, .decoding:
            return .error
        case .unexpected:
            return .critical
        }
    }
}

/// Narrow network failure classification.
/// This intentionally avoids leaking transport or vendor details.
enum NetworkFailure: Equatable, Sendable {
    case offline
    case timeout
    case serverError(code: Int)
    case invalidResponse
    case unknown(String)

    var localizedDescription: String {
        switch self {
        case .offline:
            return "No network connection is available."
        case .timeout:
            return "The request timed out. Please try again."
        case .serverError(let code):
            return "Server error occurred (code \(code))."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .unknown(let message):
            return message
        }
    }
}
