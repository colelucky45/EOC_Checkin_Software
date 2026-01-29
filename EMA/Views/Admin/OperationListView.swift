//
//  OperationListView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

@MainActor
struct OperationListView: View {

    @StateObject private var viewModel: OperationListViewModel
    @State private var isPresentingCreate: Bool = false

    // MARK: - Init

    init() {
        _viewModel = StateObject(wrappedValue: OperationListViewModel())
    }

    init(viewModel: OperationListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Operations")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isPresentingCreate = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $isPresentingCreate) {
                    CreateOperationView(
                        viewModel: CreateOperationViewModel(),
                        onSave: {
                            Task { await viewModel.load() }
                        }
                    )
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
            ProgressView("Loading operations…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else {
            listView
        }
    }

    private var listView: some View {
        List(viewModel.operations) { operation in
            NavigationLink {
                OperationDetailView(
                    viewModel: OperationDetailViewModel(operation: operation)
                )
            } label: {
                operationRow(operation)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    viewModel.operationToDelete = operation
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .contextMenu {
                Button {
                    viewModel.operationToDuplicate = operation
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }

                Button(role: .destructive) {
                    viewModel.operationToDelete = operation
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .listStyle(.insetGrouped)
        .alert("Delete Operation?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.operationToDelete = nil
            }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteOperation()
                }
            }
        } message: {
            if let op = viewModel.operationToDelete {
                Text("Are you sure you want to delete '\(op.name)'? This cannot be undone.")
            }
        }
        .sheet(item: $viewModel.operationToDuplicate) { operation in
            duplicateSheet(for: operation)
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private func operationRow(_ operation: Operation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(operation.name)
                .font(.headline)

            if operation.isRecurring {
                recurrenceLabel(for: operation)
            } else {
                Text(operation.formattedSchedule)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                StatusBadge(
                    text: operation.isActive ? "Active" : "Inactive",
                    status: operation.isActive ? .active : .inactive
                )
                StatusBadge(
                    text: operation.isVisible ? "Visible" : "Hidden",
                    status: operation.isVisible ? .info : .inactive
                )
                Text(operation.category.uppercased())
                    .font(.captionText)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func recurrenceLabel(for operation: Operation) -> some View {
        let text: String
        switch operation.recurrenceType {
        case .daily:
            text = "Daily"
        case .weekly:
            if let config = operation.recurrenceConfig, let days = config.daysOfWeek {
                let dayNames = days.map { dayName(for: $0) }.joined(separator: ", ")
                text = "Weekly: \(dayNames)"
            } else {
                text = "Weekly"
            }
        case .monthly:
            if let config = operation.recurrenceConfig, let day = config.dayOfMonth {
                text = "Monthly: Day \(day)"
            } else {
                text = "Monthly"
            }
        case .oneTime:
            text = operation.formattedSchedule
        }

        return Text(text)
            .font(.subheadline)
            .foregroundColor(.secondary)
    }

    private func dayName(for weekday: Int) -> String {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][weekday]
    }

    private func duplicateSheet(for operation: Operation) -> some View {
        DuplicateOperationView(
            viewModel: DuplicateOperationViewModel(sourceOperation: operation),
            onSave: {
                Task { await viewModel.load() }
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
