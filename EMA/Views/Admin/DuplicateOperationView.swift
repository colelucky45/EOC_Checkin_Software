//
//  DuplicateOperationView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

struct DuplicateOperationView: View {

    @StateObject private var viewModel: DuplicateOperationViewModel
    private let onSave: () -> Void

    @SwiftUI.Environment(\.dismiss) private var dismiss

    // MARK: - Init

    init(
        viewModel: DuplicateOperationViewModel,
        onSave: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSave = onSave
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Operation Name", text: $viewModel.name)

                    Picker("Category", selection: $viewModel.category) {
                        Text("Blue Sky").tag("blue")
                        Text("Gray Sky").tag("gray")
                    }

                    TextField("Description (optional)", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Recurrence") {
                    Picker("Type", selection: $viewModel.recurrenceType) {
                        Text("One-Time").tag(RecurrenceType.oneTime)
                        Text("Daily").tag(RecurrenceType.daily)
                        Text("Weekly").tag(RecurrenceType.weekly)
                        Text("Monthly").tag(RecurrenceType.monthly)
                    }

                    if viewModel.recurrenceType == .weekly {
                        weeklyDaysSelection
                    }

                    if viewModel.recurrenceType == .monthly {
                        Picker("Day of Month", selection: $viewModel.dayOfMonth) {
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                    }

                    if viewModel.recurrenceType != .oneTime {
                        TextField("Start Time (HH:mm)", text: $viewModel.recurrenceStartTime)
                        TextField("End Time (HH:mm)", text: $viewModel.recurrenceEndTime)

                        Toggle("Perpetual", isOn: $viewModel.isPerpetual)

                        if !viewModel.isPerpetual {
                            DatePicker(
                                "End Date",
                                selection: $viewModel.recurrenceEndDate,
                                displayedComponents: .date
                            )
                        }
                    }
                }

                if viewModel.recurrenceType == .oneTime {
                    Section("Schedule") {
                        Toggle("Set Start Date", isOn: $viewModel.startDateEnabled)

                        if viewModel.startDateEnabled {
                            DatePicker(
                                "Start Date",
                                selection: $viewModel.startDate,
                                displayedComponents: .date
                            )
                        }

                        Toggle("Set End Date", isOn: $viewModel.endDateEnabled)

                        if viewModel.endDateEnabled {
                            DatePicker(
                                "End Date",
                                selection: $viewModel.endDate,
                                displayedComponents: .date
                            )
                        }

                        TextField("Start Time (optional)", text: $viewModel.startTime)
                        TextField("End Time (optional)", text: $viewModel.endTime)
                    }
                }

                Section("Status") {
                    Toggle("Active", isOn: $viewModel.isActive)
                    Toggle("Visible", isOn: $viewModel.isVisible)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button("Duplicate Operation") {
                        Task {
                            await viewModel.duplicateOperation()
                            if viewModel.didSave {
                                onSave()
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isSaving)

                    if viewModel.isSaving {
                        ProgressView("Duplicating…")
                    }
                }
            }
            .navigationTitle("Duplicate Operation")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Weekly Days Selection

    private var weeklyDaysSelection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Days")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                ForEach(daysOfWeek, id: \.value) { day in
                    dayButton(day: day)
                }
            }
        }
    }

    private func dayButton(day: (name: String, value: Int)) -> some View {
        Button {
            if viewModel.selectedDaysOfWeek.contains(day.value) {
                viewModel.selectedDaysOfWeek.remove(day.value)
            } else {
                viewModel.selectedDaysOfWeek.insert(day.value)
            }
        } label: {
            Text(day.name)
                .font(.caption)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(viewModel.selectedDaysOfWeek.contains(day.value) ? Color.accentColor : Color.gray.opacity(0.2))
                .foregroundColor(viewModel.selectedDaysOfWeek.contains(day.value) ? .white : .primary)
                .cornerRadius(8)
        }
    }

    private let daysOfWeek = [
        (name: "Sun", value: 0),
        (name: "Mon", value: 1),
        (name: "Tue", value: 2),
        (name: "Wed", value: 3),
        (name: "Thu", value: 4),
        (name: "Fri", value: 5),
        (name: "Sat", value: 6)
    ]
}
