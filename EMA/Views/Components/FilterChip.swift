//
//  FilterChip.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color(.systemGray5))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        FilterChip(title: "All", isSelected: true) { }
        FilterChip(title: "Active", isSelected: false) { }
        FilterChip(title: "Archived", isSelected: false) { }
    }
    .padding()
}
