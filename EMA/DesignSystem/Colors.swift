//
//  Colors.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

/// Application color palette.
/// Uses semantic colors that adapt to light/dark mode.
extension Color {

    // MARK: - Primary Colors

    static let appPrimary = Color.blue
    static let appSecondary = Color.gray
    static let appAccent = Color.orange

    // MARK: - Status Colors

    static let appSuccess = Color.green
    static let appWarning = Color.orange
    static let appError = Color.red
    static let appInfo = Color.blue

    // MARK: - Text Colors

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(UIColor.tertiaryLabel)

    // MARK: - Background Colors

    static let backgroundPrimary = Color(UIColor.systemBackground)
    static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
    static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)

    // MARK: - Border Colors

    static let borderPrimary = Color(UIColor.separator)
    static let borderSecondary = Color(UIColor.opaqueSeparator)
}
