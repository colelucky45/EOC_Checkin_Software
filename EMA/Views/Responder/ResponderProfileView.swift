//
//  ResponderProfileView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

@MainActor
struct ResponderProfileView: View {

    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel: ResponderProfileViewModel

    init(session: SessionManager) {
        _viewModel = StateObject(wrappedValue: ResponderProfileViewModel(session: session))
    }

    init(viewModel: ResponderProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Profile")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        if viewModel.isEditing {
                            Button("Cancel") {
                                viewModel.cancelEditing()
                            }
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        if viewModel.isEditing {
                            Button("Save") {
                                Task { await viewModel.saveProfile() }
                            }
                            .disabled(viewModel.isLoading)
                        } else {
                            Button("Edit") {
                                viewModel.startEditing()
                            }
                            .disabled(viewModel.isLoading)
                        }
                    }
                }
                .task {
                    await viewModel.load()
                }
        }
        .brandedBackground()
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.user == nil {
            ProgressView("Loading profile...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let user = viewModel.user {
            profileView(user: user)
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else {
            errorView(message: "Profile unavailable.")
        }
    }

    private func profileView(user: User) -> some View {
        List {
            // Success/Error messages
            if let successMessage = viewModel.successMessage {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(successMessage)
                            .foregroundColor(.green)
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }

            Section("Personal Information") {
                if viewModel.isEditing {
                    EditableField(label: "First Name", text: $viewModel.editFirstName)
                    EditableField(label: "Last Name", text: $viewModel.editLastName)
                    EditableField(label: "Email", text: $viewModel.editEmail, keyboardType: .emailAddress)
                    EditableField(label: "Phone", text: $viewModel.editPhone, keyboardType: .phonePad)
                } else {
                    ProfileRow(label: "Name", value: user.fullName)

                    if let email = user.email {
                        ProfileRow(label: "Email", value: email)
                    }

                    if let phone = user.phone {
                        ProfileRow(label: "Phone", value: phone)
                    }
                }
            }

            Section("Organization") {
                if viewModel.isEditing {
                    EditableField(label: "Employer", text: $viewModel.editEmployer)
                    EditableField(label: "Position", text: $viewModel.editPosition)
                } else {
                    if let employer = user.employer {
                        ProfileRow(label: "Employer", value: employer)
                    }

                    if let credentialLevel = user.credentialLevel {
                        ProfileRow(label: "Position", value: credentialLevel)
                    }
                }
            }

            if !viewModel.isEditing {
                Section("Account Status") {
                    HStack {
                        Text("Status")
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(user.isActive ? "Active" : "Inactive")
                            .foregroundColor(user.isActive ? .green : .red)
                            .fontWeight(.semibold)
                    }

                    ProfileRow(
                        label: "Member Since",
                        value: format(date: user.createdAt)
                    )
                }
            }
        }
        .listStyle(.insetGrouped)
        .disabled(viewModel.isLoading)
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
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - ProfileRow Component

private struct ProfileRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - EditableField Component

private struct EditableField: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)

            TextField(label, text: $text)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                .multilineTextAlignment(.trailing)
        }
    }
}
