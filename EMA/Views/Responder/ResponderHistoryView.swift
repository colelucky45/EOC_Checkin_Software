//
//  ResponderHistoryView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

@MainActor
struct ResponderHistoryView: View {

    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel: ResponderHistoryViewModel

    init() {
        _viewModel = StateObject(wrappedValue: ResponderHistoryViewModel())
    }

    init(viewModel: ResponderHistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("My History")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task {
                                if let userId = session.currentUser?.id {
                                    await viewModel.load(userId: userId)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                .task {
                    if let userId = session.currentUser?.id {
                        await viewModel.load(userId: userId)
                    }
                }
        }
        .brandedBackground()
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading history...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else if viewModel.history.isEmpty {
            emptyView
        } else {
            listView
        }
    }

    private var listView: some View {
        List(viewModel.history) { entry in
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.operationName)
                    .font(.headline)

                HStack {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(.green)
                        .font(.caption)

                    Text("In: \(format(date: entry.checkInTime))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let checkOutTime = entry.checkOutTime {
                    HStack {
                        Image(systemName: "arrow.left.circle")
                            .foregroundColor(.orange)
                            .font(.caption)

                        Text("Out: \(format(date: checkOutTime))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if let duration = entry.duration {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                                .font(.caption)

                            Text("Duration: \(duration)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundColor(.green)
                            .font(.caption)

                        Text("Currently checked in")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }

                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.insetGrouped)
        .refreshable {
            if let userId = session.currentUser?.id {
                await viewModel.load(userId: userId)
            }
        }
    }

    private var emptyView: some View {
        EmptyStateView(
            icon: "clock.badge.checkmark",
            message: "No check-in history available."
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
