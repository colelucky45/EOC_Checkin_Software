//
//  SettingsView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

struct SettingsView: View {

    @StateObject private var viewModel: SettingsViewModel

    // MARK: - Init

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        Form {
            Section("Kiosk Mode") {
                content
            }

            Section("About") {
                LabeledContent("App Version") {
                    Text(Bundle.main.appVersion)
                        .foregroundColor(.secondary)
                }

                LabeledContent("Build") {
                    Text(Bundle.main.buildNumber)
                        .foregroundColor(.secondary)
                }

                Button {
                    if let url = URL(string: "mailto:support@example.com") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Text("Contact Support")
                        Spacer()
                        Image(systemName: "envelope")
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .task {
            await viewModel.startRealtimeUpdates()
        }
        .onDisappear {
            Task {
                await viewModel.stopRealtimeUpdates()
            }
        }
        .brandedBackground()
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading kiosk settings…")
        } else if let error = viewModel.errorMessage {
            Text(error)
                .foregroundColor(.red)
        } else if let context = viewModel.kioskContext {
            Picker("Kiosk Mode", selection: kioskModeBinding(current: context.kioskMode)) {
                Text("Check In").tag(KioskMode.checkIn)
                Text("Check Out").tag(KioskMode.checkOut)
                Text("Meal").tag(KioskMode.meal)
            }
            .pickerStyle(.segmented)
        } else {
            Text("Kiosk settings unavailable.")
                .foregroundColor(.secondary)
        }
    }

    private func kioskModeBinding(current: KioskMode) -> Binding<KioskMode> {
        Binding(
            get: { current },
            set: { value in
                Task { await viewModel.setKioskMode(value) }
            }
        )
    }
}
