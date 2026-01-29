//
//  BundleExtensions.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation

extension Bundle {
    /// Returns the app version in format: "1.0 (1)"
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    /// Returns just the version number (e.g., "1.0")
    var versionNumber: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// Returns just the build number (e.g., "1")
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// Returns the full app name
    var appName: String {
        infoDictionary?["CFBundleName"] as? String ?? "EOC Check-In System"
    }

    /// Returns the display name (shown on home screen)
    var displayName: String {
        infoDictionary?["CFBundleDisplayName"] as? String ?? "EOC Check-In"
    }
}
