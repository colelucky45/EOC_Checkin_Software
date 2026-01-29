//
//  ManualCheckInView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

@MainActor
struct ManualCheckInView: View {

    @StateObject private var viewModel: ManualCheckInViewModel

    // MARK: - Init

    init() {
        _viewModel = StateObject(wrappedValue: ManualCheckInViewModel())
    }

    init(viewModel: ManualCheckInViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Select User") {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.users.isEmpty {
                        Text("No active users available.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("User", selection: $viewModel.selectedUserId) {
                            Text("Select a user").tag(nil as UUID?)
                            ForEach(viewModel.users) { user in
                                Text(user.fullName).tag(user.id as UUID?)
                            }
                        }
                    }
                }

                Section("Select Operation (for Check-In)") {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.operations.isEmpty {
                        Text("No active operations available.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Operation", selection: $viewModel.selectedOperationId) {
                            Text("Select an operation").tag(nil as UUID?)
                            ForEach(viewModel.operations) { operation in
                                Text(operation.name).tag(operation.id as UUID?)
                            }
                        }
                    }
                }

                Section("Notes (Optional)") {
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 60)
                }

                Section {
                    PrimaryButton(
                        title: "Check In",
                        action: { Task { await viewModel.performCheckIn() } },
                        isLoading: viewModel.isPerformingAction,
                        isDisabled: viewModel.selectedUserId == nil || viewModel.selectedOperationId == nil
                    )

                    SecondaryButton(
                        title: "Check Out",
                        action: { Task { await viewModel.performCheckOut() } },
                        isLoading: viewModel.isPerformingAction,
                        isDisabled: viewModel.selectedUserId == nil
                    )
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

                if let success = viewModel.successMessage {
                    Section {
                        Text(success)
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Manual Check-In")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Reset") {
                        viewModel.resetForm()
                    }
                    .disabled(viewModel.isPerformingAction)
                }
            }
            .task {
                await viewModel.load()
            }
        }
        .brandedBackground()
    }
}
