//
//  IconLabelRow.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

/// Row with icon and label for consistent info display.
struct IconLabelRow: View {

    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(.appPrimary)
                .frame(width: 24)

            Text(label)
                .font(.labelRegular)
                .foregroundColor(.textSecondary)

            Spacer()

            Text(value)
                .font(.bodyRegular)
                .foregroundColor(.textPrimary)
        }
        .padding(.vertical, Spacing.xxs)
    }
}
