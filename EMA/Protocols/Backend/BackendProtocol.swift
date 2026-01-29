//
//  BackendProtocol.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Container protocol providing all backend services
/// Implement this to integrate with your backend (Firebase, AWS, Azure, etc.)
public protocol BackendProtocol: Sendable {
    var auth: AuthProviderProtocol { get }
    var database: DatabaseProviderProtocol { get }
    var realtime: RealtimeProviderProtocol { get }
    var logger: RemoteLoggerProtocol { get }
}
