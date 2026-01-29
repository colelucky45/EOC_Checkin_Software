//
//  DestructiveButton.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

/// Destructive action button with warning styling.
struct DestructiveButton: View {

    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(title)
                    .font(.buttonText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.shared.buttonHeight)
            .foregroundColor(.white)
            .background(isDisabled ? Color.gray : Color.appError)
            .cornerRadius(AppTheme.shared.buttonCornerRadius)
        }
        .disabled(isDisabled || isLoading)
    }
}
