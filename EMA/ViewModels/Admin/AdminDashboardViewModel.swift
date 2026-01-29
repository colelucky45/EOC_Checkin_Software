//
//  AdminDashboardViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import Combine

@MainActor
final class AdminDashboardViewModel: ObservableObject {

    // MARK: - Published State

    /// Currently selected tab index
    @Published var selectedTab: Int = 0

    // MARK: - Tab Definitions

    enum Tab: Int, CaseIterable {
        case operations = 0
        case checkIns = 1
        case meals = 2
        case personnel = 3
        case settings = 4

        var title: String {
            switch self {
            case .operations: return "Operations"
            case .checkIns: return "Check-Ins"
            case .meals: return "Meals"
            case .personnel: return "Personnel"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .operations: return "calendar"
            case .checkIns: return "clock"
            case .meals: return "fork.knife"
            case .personnel: return "person.3"
            case .settings: return "gear"
            }
        }
    }

    // MARK: - Public API

    func selectTab(_ tab: Tab) {
        selectedTab = tab.rawValue
    }
}
