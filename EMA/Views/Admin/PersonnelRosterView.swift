//
//  PersonnelListView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

@MainActor
struct PersonnelRosterView: View {

    @StateObject private var viewModel: PersonnelRosterViewModel

    // MARK: - Init

    init() {
        _viewModel = StateObject(wrappedValue: PersonnelRosterViewModel())
    }

    init(viewModel: PersonnelRosterViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterPicker
                content
            }
            .navigationTitle("Personnel")
            .searchable(text: $viewModel.searchText, prompt: "Search personnel")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
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

    // MARK: - Filter Picker

    private var filterPicker: some View {
        Picker("Filter", selection: $viewModel.selectedFilter) {
            ForEach(PersonnelRosterViewModel.FilterType.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading roster…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else if viewModel.filteredPersonnel.isEmpty {
            emptyView
        } else {
            listView
        }
    }

    private var listView: some View {
        List {
            ForEach(viewModel.filteredPersonnel) { person in
                personRow(person)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.personToDelete = person
                            viewModel.showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
        .alert("Delete User?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.personToDelete = nil
            }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteUser()
                }
            }
        } message: {
            if let person = viewModel.personToDelete {
                Text("Are you sure you want to permanently delete '\(person.name)'? This action cannot be undone and will remove all their data from the system.")
            }
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private func personRow(_ person: PersonnelRosterViewModel.PersonnelRow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(person.name)
                        .font(.headline)

                    HStack(spacing: 8) {
                        Text(person.role.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let employer = person.employer {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(employer)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let position = person.position {
                        Text(position)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                StatusBadge(
                    text: person.isPresent ? "In Building" : "Out",
                    status: person.isPresent ? .active : .inactive
                )
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyView: some View {
        let message: String
        switch viewModel.selectedFilter {
        case .all, .checkedIn:
            message = "No personnel currently in the building."
        case .checkedOut:
            message = "No personnel have checked out yet."
        case .registered:
            message = "No registered users found."
        }

        return EmptyStateView(
            icon: "person.3",
            message: message
        )
    }

    private func errorView(message: String) -> some View {
        EmptyStateView(
            icon: "exclamationmark.triangle.fill",
            message: message
        )
    }
}
