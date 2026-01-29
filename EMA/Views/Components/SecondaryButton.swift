//
//  SecondaryButton.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

/// Secondary action button with outline styling.
struct SecondaryButton: View {

    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                        .scaleEffect(0.8)
                }
                Text(title)
                    .font(.buttonText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.shared.buttonHeight)
            .foregroundColor(isDisabled ? .gray : .appPrimary)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.shared.buttonCornerRadius)
                    .stroke(isDisabled ? Color.gray : Color.appPrimary, lineWidth: 2)
            )
        }
        .disabled(isDisabled || isLoading)
    }
}
