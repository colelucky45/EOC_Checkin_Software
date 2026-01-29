//
//  ActivationModeView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

@MainActor
struct ActivationModeView: View {

    @StateObject private var viewModel: ActivationModeViewModel

    // MARK: - Init

    init() {
        _viewModel = StateObject(wrappedValue: ActivationModeViewModel())
    }

    init(viewModel: ActivationModeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: Spacing.md) {
            header

            content

            Spacer()
        }
        .padding(Spacing.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .brandedBackground()
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            Text("System Mode")
                .font(.heading2)

            Text("Controls the building-wide operational posture.")
                .font(.bodyRegular)
                .foregroundColor(.textSecondary)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading system mode…")
                .padding(.top, 8)
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else if let mode = viewModel.currentMode {
            modePicker(current: mode)
        } else {
            Text("System mode unavailable.")
                .foregroundColor(.secondary)
        }
    }

    private func modePicker(current: SystemSettingsService.SystemMode) -> some View {
        Picker("System Mode", selection: modeBinding(current: current)) {
            Text("Blue Sky").tag(SystemSettingsService.SystemMode.blue)
            Text("Gray Sky").tag(SystemSettingsService.SystemMode.gray)
        }
        .pickerStyle(.segmented)
        .padding(.top, 8)
    }

    private func modeBinding(current: SystemSettingsService.SystemMode) -> Binding<SystemSettingsService.SystemMode> {
        Binding(
            get: { current },
            set: { value in
                Task { await viewModel.setMode(value) }
            }
        )
    }

    private func errorView(message: String) -> some View {
        EmptyStateView(
            icon: "exclamationmark.triangle.fill",
            message: message
        )
    }
}
