//
//  MockRemoteLogger.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Mock remote logger for testing
final class MockRemoteLogger: RemoteLoggerProtocol, @unchecked Sendable {
    func logError(severity: String, message: String, details: [String: Any]?) async {
        #if DEBUG
        print("[MockLogger] \(severity): \(message)")
        #endif
    }
}
