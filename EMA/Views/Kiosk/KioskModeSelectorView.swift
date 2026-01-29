//
//  KioskModeSelectorView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

struct KioskModeSelectorView: View {

    @StateObject private var viewModel: KioskModeSelectorViewModel
    @State private var selectedMode: KioskMode = .checkIn

    // MARK: - Init

    init(viewModel: KioskModeSelectorViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 24) {

            header

            content

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .brandedBackground()
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text("Kiosk Mode")
                .font(.heading1)

            Text("Select how this kiosk should operate")
                .font(.heading3)
                .foregroundColor(.textSecondary)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading kiosk settings…")
                .padding()
        } else if let context = viewModel.kioskContext {
            modeSelector(context: context)
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        }
    }

    // MARK: - Mode Selector

    private func modeSelector(context: KioskContext) -> some View {
        VStack(spacing: 24) {

            Picker(
                "Kiosk Mode",
                selection: $selectedMode
            ) {
                Text("Check In").tag(KioskMode.checkIn)
                Text("Check Out").tag(KioskMode.checkOut)
                Text("Meals").tag(KioskMode.meal)
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedMode) { _, newMode in
                Task {
                    await viewModel.setKioskMode(newMode)
                }
            }
            .onAppear {
                selectedMode = context.kioskMode
            }

            systemStatus(context: context)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    // MARK: - System Status

    private func systemStatus(context: KioskContext) -> some View {
        VStack(spacing: 8) {
            Text("System Mode")
                .font(.heading4)

            Text(context.systemMode == .blueSky ? "Blue Sky" : "Gray Sky")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(context.systemMode == .blueSky ? .blue : .gray)
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        EmptyStateView(
            icon: "exclamationmark.triangle.fill",
            message: message
        )
    }
}
