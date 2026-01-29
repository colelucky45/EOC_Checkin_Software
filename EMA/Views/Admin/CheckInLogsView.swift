//
//  CheckInLogsView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

@MainActor
struct CheckInLogsView: View {

    @StateObject private var viewModel: CheckInLogsViewModel

    // MARK: - Init

    init() {
        _viewModel = StateObject(wrappedValue: CheckInLogsViewModel())
    }

    init(viewModel: CheckInLogsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterChips
                content
            }
            .navigationTitle("Check-In Logs")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await viewModel.startRealtimeUpdates()
            }
            .onDisappear {
                Task {
                    await viewModel.stopRealtimeUpdates()
                }
            }
        }
        .brandedBackground()
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CheckInLogsViewModel.FilterType.allCases) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.selectedFilter == filter,
                        action: { viewModel.selectedFilter = filter }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading logs…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else if viewModel.logs.isEmpty {
            emptyView
        } else {
            listView
        }
    }

    private var listView: some View {
        List(viewModel.logs) { entry in
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.userName)
                    .font(.headline)

                Text("Checked in: \(format(date: entry.checkInTime))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let checkout = entry.checkOutTime {
                    Text("Checked out: \(format(date: checkout))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Currently in building")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.load()
        }
    }

    private var emptyView: some View {
        EmptyStateView(
            icon: "clock",
            message: "No check-in logs available."
        )
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
