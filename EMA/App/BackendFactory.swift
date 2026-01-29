//
//  BackendFactory.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Central factory for backend services
/// Change `current` to swap backends (Firebase, AWS, Azure, etc.)
enum BackendFactory {
    /// The current backend implementation
    /// To use a different backend, create your own implementation of BackendProtocol
    /// and assign it here (e.g., FirebaseBackend.shared, AWSBackend.shared)
    static var current: BackendProtocol = MockBackend.shared
}
