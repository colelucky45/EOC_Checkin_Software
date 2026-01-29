//
//  MealLogsView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

@MainActor
struct MealLogsView: View {

    @StateObject private var viewModel: MealLogsViewModel

    // MARK: - Init

    init() {
        _viewModel = StateObject(wrappedValue: MealLogsViewModel())
    }

    init(viewModel: MealLogsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Meal Logs")
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

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading meals…")
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
                Text(entry.mealSummary)
                    .font(.headline)

                Text(entry.userName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Served: \(format(date: entry.servedAt))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
            icon: "fork.knife",
            message: "No meal logs available."
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
