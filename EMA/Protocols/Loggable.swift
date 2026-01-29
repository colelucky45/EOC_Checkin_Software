//
//  Loggable.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Protocol for types that can be logged.
/// Provides structured logging context for debugging.
protocol Loggable {
    var logDescription: String { get }
    var logMetadata: [String: Any] { get }
}

extension Loggable {
    var logMetadata: [String: Any] {
        [:]
    }
}
