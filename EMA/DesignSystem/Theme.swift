//
//  Theme.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI
import Combine

/// Centralized theme configuration.
/// Combines colors, typography, spacing, and other design tokens.
struct AppTheme {

    // MARK: - Singleton

    static let shared = AppTheme()

    private init() {}

    // MARK: - Colors

    var primaryColor: Color { .appPrimary }
    var secondaryColor: Color { .appSecondary }
    var accentColor: Color { .appAccent }

    var successColor: Color { .appSuccess }
    var warningColor: Color { .appWarning }
    var errorColor: Color { .appError }

    var backgroundColor: Color { .backgroundPrimary }

    // MARK: - Typography

    var headingFont: Font { .heading2 }
    var bodyFont: Font { .bodyRegular }
    var buttonFont: Font { .buttonText }

    // MARK: - Layout

    var cardPadding: CGFloat { Spacing.cardPadding }
    var cardCornerRadius: CGFloat { CornerRadius.card }
    var buttonCornerRadius: CGFloat { CornerRadius.button }

    var defaultShadow: AppShadow { .md }

    // MARK: - Dimensions

    var buttonHeight: CGFloat { 50 }
    var inputHeight: CGFloat { 44 }
}
