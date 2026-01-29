//
//  MealServiceView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

@MainActor
struct MealServiceView: View {

    @StateObject private var viewModel: MealServiceViewModel

    // MARK: - Init

    init() {
        _viewModel = StateObject(wrappedValue: MealServiceViewModel())
    }

    init(viewModel: MealServiceViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Meal Type") {
                    Picker("Type", selection: $viewModel.selectedMealType) {
                        ForEach(viewModel.mealTypes, id: \.self) { mealType in
                            Text(mealType).tag(mealType)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Quantity") {
                    Stepper("\(viewModel.quantity) meal(s)", value: $viewModel.quantity, in: 1...100)
                }

                Section("User (Optional)") {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.users.isEmpty {
                        Text("No active users available.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("User", selection: $viewModel.selectedUserId) {
                            Text("None").tag(nil as UUID?)
                            ForEach(viewModel.users) { user in
                                Text(user.fullName).tag(user.id as UUID?)
                            }
                        }
                    }
                }

                Section("Operation (Optional)") {
                    if viewModel.isLoading {
                        ProgressView()
                    } else if viewModel.operations.isEmpty {
                        Text("No active operations available.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Operation", selection: $viewModel.selectedOperationId) {
                            Text("None").tag(nil as UUID?)
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
                        title: "Log Meal",
                        action: { Task { await viewModel.logMeal() } },
                        isLoading: viewModel.isSubmitting,
                        isDisabled: false
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
            .navigationTitle("Meal Service")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Reset") {
                        viewModel.resetForm()
                    }
                    .disabled(viewModel.isSubmitting)
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
}
