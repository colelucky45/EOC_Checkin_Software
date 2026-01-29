//
//  EmptyStateView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

/// Empty state placeholder using iOS 17+ ContentUnavailableView.
/// Provides native iOS empty state experience with icon, message, and optional action button.
struct EmptyStateView: View {

    let icon: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        if #available(iOS 17.0, *) {
            if let actionTitle = actionTitle, let action = action {
                ContentUnavailableView {
                    Label(message, systemImage: icon)
                } description: {
                    Text("Tap the button below to get started.")
                } actions: {
                    Button(actionTitle, action: action)
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ContentUnavailableView(message, systemImage: icon)
            }
        } else {
            // Fallback for iOS 16 and earlier
            VStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundColor(.textSecondary)

                Text(message)
                    .font(.bodyRegular)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)

                if let actionTitle = actionTitle, let action = action {
                    Button(action: action) {
                        Text(actionTitle)
                            .font(.buttonText)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(Spacing.xl)
        }
    }
}
