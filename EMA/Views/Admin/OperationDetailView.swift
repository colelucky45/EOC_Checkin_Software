//
//  OperationDetailView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

struct OperationDetailView: View {

    @StateObject private var viewModel: OperationDetailViewModel

    // MARK: - Init

    init(viewModel: OperationDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        Form {
            Section("Summary") {
                LabeledContent("Name") {
                    Text(viewModel.operation.name)
                }

                LabeledContent("Category") {
                    Text(viewModel.operation.category.uppercased())
                }

                if let description = viewModel.operation.description, !description.isEmpty {
                    LabeledContent("Description") {
                        Text(description)
                    }
                }
            }

            Section("Schedule") {
                LabeledContent("Schedule") {
                    Text(viewModel.operation.formattedSchedule)
                        .foregroundColor(.secondary)
                }
            }

            Section("Status") {
                Toggle("Active", isOn: activeBinding)
                    .disabled(viewModel.isLoading)

                Toggle("Visible", isOn: visibleBinding)
                    .disabled(viewModel.isLoading)

                LabeledContent("Created") {
                    Text(Self.dateFormatter.string(from: viewModel.operation.createdAt))
                        .foregroundColor(.secondary)
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Operation Details")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .brandedBackground()
    }

    // MARK: - Bindings

    private var activeBinding: Binding<Bool> {
        Binding(
            get: { viewModel.operation.isActive },
            set: { value in
                Task { await viewModel.setActive(value) }
            }
        )
    }

    private var visibleBinding: Binding<Bool> {
        Binding(
            get: { viewModel.operation.isVisible },
            set: { value in
                Task { await viewModel.setVisible(value) }
            }
        )
    }

    // MARK: - Helpers

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
