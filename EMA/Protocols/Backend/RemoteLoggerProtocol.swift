//
//  RemoteLoggerProtocol.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

/// Protocol for remote error logging (CloudWatch, Crashlytics, Sentry, etc.)
public protocol RemoteLoggerProtocol: Sendable {
    func logError(severity: String, message: String, details: [String: Any]?) async
}
