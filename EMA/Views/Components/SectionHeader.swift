//
//  SectionHeader.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

/// Section header with consistent styling.
struct SectionHeader: View {

    let title: String

    var body: some View {
        Text(title)
            .font(.heading4)
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Spacing.xs)
    }
}
