//
//  StatusBadge.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

/// Status badge with color-coded background.
struct StatusBadge: View {

    let text: String
    let status: Status

    enum Status {
        case active
        case inactive
        case warning
        case error
        case info

        var color: Color {
            switch self {
            case .active: return .appSuccess
            case .inactive: return .appSecondary
            case .warning: return .appWarning
            case .error: return .appError
            case .info: return .appInfo
            }
        }
    }

    var body: some View {
        Text(text)
            .font(.captionText)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(status.color)
            .cornerRadius(CornerRadius.sm)
    }
}
