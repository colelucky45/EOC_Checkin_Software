//
//  NetworkError.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//  Low-level networking error representation.
//  This type should never be exposed directly to Views.

import Foundation

/// Represents transport and protocol-level failures.
/// These errors are intentionally narrow and vendor-agnostic.
enum NetworkError: Error, Equatable {
    case offline
    case timeout
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingFailed
    case unauthorized
    case forbidden
    case unknown(String)

    /// Maps a NetworkError into a user-safe AppError.
    /// This is the ONLY place where network failures cross the Core boundary.
    func toAppError() -> AppError {
        switch self {
        case .offline:
            return .network(.offline)

        case .timeout:
            return .network(.timeout)

        case .invalidResponse:
            return .network(.invalidResponse)

        case .serverError(let statusCode):
            return .network(.serverError(code: statusCode))

        case .unauthorized:
            return .authentication("Your session has expired. Please sign in again.")

        case .forbidden:
            return .authorization("You do not have permission to perform this action.")

        case .decodingFailed:
            return .decoding("Failed to process data from the server.")

        case .unknown(let message):
            return .network(.unknown(message))
        }
    }
}

// MARK: - URLSession / Transport Helpers

extension NetworkError {
    /// Attempts to infer a NetworkError from a generic Error.
    /// Safe to call inside repositories and networking clients.
    static func from(_ error: Error) -> NetworkError {
        let nsError = error as NSError

        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                return .offline
            case NSURLErrorTimedOut:
                return .timeout
            case NSURLErrorUserAuthenticationRequired:
                return .unauthorized
            default:
                return .unknown(nsError.localizedDescription)
            }
        }

        return .unknown(error.localizedDescription)
    }

    /// Attempts to infer a NetworkError from an HTTP response.
    static func from(statusCode: Int) -> NetworkError {
        switch statusCode {
        case 200..<300:
            return .unknown("Unexpected success mapping call.")
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .invalidResponse
        case 500..<600:
            return .serverError(statusCode: statusCode)
        default:
            return .unknown("Unhandled HTTP status code: \(statusCode)")
        }
    }
}
