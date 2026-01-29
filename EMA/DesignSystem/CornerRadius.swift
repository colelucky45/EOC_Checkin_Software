//
//  CornerRadius.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI
import Combine

/// Corner radius values for consistent rounded corners.
/// Uses standard iOS conventions.
enum CornerRadius {

    // MARK: - Radius Values

    static let none: CGFloat = 0
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let round: CGFloat = 999

    // MARK: - Semantic

    static let button: CGFloat = md
    static let card: CGFloat = lg
    static let sheet: CGFloat = xl
}
