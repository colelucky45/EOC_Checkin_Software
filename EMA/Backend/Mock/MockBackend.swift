//
//  MockBackend.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Mock backend for development, testing, and SwiftUI previews
final class MockBackend: BackendProtocol, @unchecked Sendable {
    static let shared = MockBackend()

    let auth: AuthProviderProtocol = MockAuthProvider()
    let database: DatabaseProviderProtocol = MockDatabaseProvider()
    let realtime: RealtimeProviderProtocol = MockRealtimeProvider()
    let logger: RemoteLoggerProtocol = MockRemoteLogger()

    private init() {}
}
