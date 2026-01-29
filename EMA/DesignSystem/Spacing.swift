//
//  Spacing.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI
import Combine

/// Consistent spacing values for layout.
/// Uses 4pt grid system for alignment.
enum Spacing {

    // MARK: - Base Scale (4pt grid)

    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48

    // MARK: - Semantic

    static let cardPadding: CGFloat = md
    static let sectionSpacing: CGFloat = lg
    static let itemSpacing: CGFloat = sm
    static let screenPadding: CGFloat = md
}
