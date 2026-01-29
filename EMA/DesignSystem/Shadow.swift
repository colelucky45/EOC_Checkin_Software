//
//  Shadow.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI
import Combine

/// Shadow styling for depth and elevation.
/// Provides consistent shadow effects across the app.
enum AppShadow {

    // MARK: - Shadow Definitions

    case sm
    case md
    case lg

    var radius: CGFloat {
        switch self {
        case .sm: return 2
        case .md: return 4
        case .lg: return 8
        }
    }

    var x: CGFloat {
        0
    }

    var y: CGFloat {
        switch self {
        case .sm: return 1
        case .md: return 2
        case .lg: return 4
        }
    }

    var opacity: Double {
        switch self {
        case .sm: return 0.1
        case .md: return 0.15
        case .lg: return 0.2
        }
    }
}

extension View {

    // MARK: - Shadow Modifiers

    func shadow(_ shadow: AppShadow) -> some View {
        self.shadow(
            color: Color.black.opacity(shadow.opacity),
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}
