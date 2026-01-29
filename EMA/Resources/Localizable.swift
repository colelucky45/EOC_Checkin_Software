//
//  Localizable.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import Combine

/// Localized string keys for multi-language support.
/// Provides type-safe access to localized strings.
enum LocalizedString {

    // MARK: - Common

    static let ok = NSLocalizedString("common.ok", value: "OK", comment: "OK button")
    static let cancel = NSLocalizedString("common.cancel", value: "Cancel", comment: "Cancel button")
    static let save = NSLocalizedString("common.save", value: "Save", comment: "Save button")
    static let delete = NSLocalizedString("common.delete", value: "Delete", comment: "Delete button")
    static let loading = NSLocalizedString("common.loading", value: "Loading...", comment: "Loading indicator")

    // MARK: - Auth

    static let login = NSLocalizedString("auth.login", value: "Login", comment: "Login button")
    static let logout = NSLocalizedString("auth.logout", value: "Logout", comment: "Logout button")
    static let signup = NSLocalizedString("auth.signup", value: "Sign Up", comment: "Sign up button")

    // MARK: - Errors

    static let genericError = NSLocalizedString("error.generic", value: "An error occurred", comment: "Generic error message")
    static let networkError = NSLocalizedString("error.network", value: "Network connection failed", comment: "Network error")
}
