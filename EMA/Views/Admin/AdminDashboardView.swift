//
//  AdminDashboardView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

struct AdminDashboardView: View {

    @EnvironmentObject private var session: SessionManager
    @State private var isSyncing: Bool = false
    @State private var queueCount: Int = 0

    var body: some View {
        TabView {
            OperationListView()
                .tabItem {
                    Label("Operations", systemImage: "calendar")
                }

            CheckInLogsView()
                .tabItem {
                    Label("Check-Ins", systemImage: "clock")
                }

            MealLogsView()
                .tabItem {
                    Label("Meals", systemImage: "fork.knife")
                }

            PersonnelRosterView()
                .tabItem {
                    Label("Personnel", systemImage: "person.3")
                }

            settingsTab
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .badge(queueCount > 0 ? "\(queueCount)" : "")
        }
        .ignoresSafeArea()
        .brandedBackground()
        .task {
            await updateQueueCount()
        }
    }

    // MARK: - Queue Counter

    private func updateQueueCount() async {
        do {
            let pending = try await WriteQueue.shared.pendingWrites()
            queueCount = pending.count
        } catch {
            queueCount = 0
        }

        // Update every 10 seconds
        try? await Task.sleep(nanoseconds: 10_000_000_000)
        await updateQueueCount()
    }

    private var settingsTab: some View {
        NavigationStack {
            List {
                Section("System") {
                    NavigationLink {
                        ActivationModeView()
                    } label: {
                        Label("System Mode", systemImage: "building.2")
                    }
                }

                Section("Kiosk") {
                    NavigationLink {
                        SettingsView(
                            viewModel: SettingsViewModel(
                                kioskService: KioskService(sessionManager: session)
                            )
                        )
                    } label: {
                        Label("Kiosk Settings", systemImage: "tablet")
                    }
                }

                Section("Admin Tools") {
                    NavigationLink {
                        AdminQRView(session: session)
                    } label: {
                        Label("Admin QR", systemImage: "qrcode")
                    }

                    NavigationLink {
                        ManualCheckInView()
                    } label: {
                        Label("Manual Check-In", systemImage: "person.badge.plus")
                    }

                    NavigationLink {
                        MealServiceView()
                    } label: {
                        Label("Meal Service", systemImage: "fork.knife.circle")
                    }
                }

                Section("Data Sync") {
                    Button {
                        Task {
                            isSyncing = true
                            await session.triggerManualSync()
                            isSyncing = false
                        }
                    } label: {
                        HStack {
                            Label("Sync Data", systemImage: "arrow.triangle.2.circlepath")

                            Spacer()

                            if isSyncing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                        }
                    }
                    .disabled(isSyncing)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
