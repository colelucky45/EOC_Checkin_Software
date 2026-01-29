//
//  ResponderHomeView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

@MainActor
struct ResponderHomeView: View {

    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel: ResponderHomeViewModel

    init(session: SessionManager) {
        _viewModel = StateObject(wrappedValue: ResponderHomeViewModel(session: session))
    }

    init(viewModel: ResponderHomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Status")
                .task {
                    if let userId = session.currentUser?.id {
                        await viewModel.startRealtimeUpdates(userId: userId)
                    }
                }
                .onDisappear {
                    Task {
                        await viewModel.stopRealtimeUpdates()
                    }
                }
        }
        .brandedBackground()
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading status…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else if session.currentUser == nil {
            errorView(message: "Responder profile unavailable.")
        } else {
            statusView
        }
    }

    private var statusView: some View {
        VStack(spacing: Spacing.lg) {
            welcomeCard
            statusCard
            Spacer()
        }
        .padding(Spacing.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary.ignoresSafeArea())
    }

    private var welcomeCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if let userName = session.currentUser?.fullName {
                    Text("Hello, \(userName)!")
                        .font(.heading2)
                        .foregroundColor(.textPrimary)
                } else {
                    Text("Hello!")
                        .font(.heading2)
                        .foregroundColor(.textPrimary)
                }

                Text("Welcome to EOC Check-In!")
                    .font(.bodyRegular)
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var statusCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Check-In Status")
                    .font(.heading4)

                Text(statusText)
                    .font(.heading3)
                    .foregroundColor(statusColor)

                if let checkInTime = viewModel.checkInTime {
                    Text("Checked in at \(format(date: checkInTime))")
                        .font(.bodySmall)
                        .foregroundColor(.textSecondary)
                }

                if viewModel.isCheckedIn == true {
                    Text("Operation: \(viewModel.operationName)")
                        .font(.bodyRegular)
                        .foregroundColor(.textSecondary)
                        .padding(.top, Spacing.xs)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var statusText: String {
        guard let isCheckedIn = viewModel.isCheckedIn else {
            return "Unknown"
        }
        return isCheckedIn ? "Checked In" : "Not Checked In"
    }

    private var statusColor: Color {
        guard let isCheckedIn = viewModel.isCheckedIn else {
            return .textSecondary
        }
        return isCheckedIn ? .appSuccess : .appSecondary
    }

    private func errorView(message: String) -> some View {
        EmptyStateView(
            icon: "exclamationmark.triangle.fill",
            message: message
        )
    }

    private func format(date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
