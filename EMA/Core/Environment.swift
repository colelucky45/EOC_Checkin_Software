//  Environment.swift
//
//  EMACheckIn
//  Created by Cole Lucky on 12/11/25.
//  Centralized environment awareness.
//  This file defines how the app understands its runtime context.

import Foundation

/// Represents the current runtime environment of the app.
enum AppEnvironment: String {
    case debug
    case staging
    case production
}

/// Global environment access point.
/// This should be read-only outside Core.
struct Environment {

    /// The resolved application environment.
    static let current: AppEnvironment = {
        // Prefer explicit environment configuration if present
        if let value = Bundle.main.object(
            forInfoDictionaryKey: "APP_ENV"
        ) as? String,
           let env = AppEnvironment(rawValue: value.lowercased()) {
            return env
        }

        #if DEBUG
        return .debug
        #else
        return .production
        #endif
    }()

    /// Indicates whether verbose logging and diagnostics are enabled.
    static var isDebug: Bool {
        current == .debug
    }

    /// Indicates whether the app is running in a production environment.
    static var isProduction: Bool {
        current == .production
    }

    /// Human-readable environment label (safe for logs).
    static var label: String {
        switch current {
        case .debug:
            return "DEBUG"
        case .staging:
            return "STAGING"
        case .production:
            return "PRODUCTION"
        }
    }

    /// Convenience hook for environment-gated behavior.
    /// Use sparingly and intentionally.
    static func requireDebug(_ action: () -> Void) {
        guard isDebug else { return }
        action()
    }
}
