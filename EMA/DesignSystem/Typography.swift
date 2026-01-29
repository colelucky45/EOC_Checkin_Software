//
//  Typography.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI
import Combine

/// Typography system for consistent text styling.
/// Uses standard iOS font styles with semantic naming.
extension Font {

    // MARK: - Headings

    static let heading1 = Font.largeTitle.weight(.bold)
    static let heading2 = Font.title.weight(.semibold)
    static let heading3 = Font.title2.weight(.semibold)
    static let heading4 = Font.title3.weight(.medium)

    // MARK: - Body

    static let bodyLarge = Font.body.weight(.regular)
    static let bodyRegular = Font.body
    static let bodySmall = Font.callout

    // MARK: - Labels

    static let labelLarge = Font.subheadline.weight(.semibold)
    static let labelRegular = Font.subheadline
    static let labelSmall = Font.caption.weight(.medium)

    // MARK: - Utility

    static let captionText = Font.caption
    static let footnoteText = Font.footnote
    static let buttonText = Font.body.weight(.semibold)
}
