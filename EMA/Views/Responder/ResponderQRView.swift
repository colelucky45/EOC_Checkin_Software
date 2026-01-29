//
//  ResponderQRView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

@MainActor
struct ResponderQRView: View {

    @EnvironmentObject private var session: SessionManager
    @StateObject private var viewModel: ResponderQRViewModel
    @State private var showCopiedToast: Bool = false

    // MARK: - Init

    init(session: SessionManager) {
        _viewModel = StateObject(wrappedValue: ResponderQRViewModel(session: session))
    }

    init(viewModel: ResponderQRViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("My QR Code")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Refresh") {
                            Task { await viewModel.refresh() }
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                .task {
                    await viewModel.load()
                }
        }
        .brandedBackground()
        .onAppear {
            Haptics.light()
        }
        .overlay(alignment: .top) {
            if showCopiedToast {
                copiedToast
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: showCopiedToast)
    }

    // MARK: - Copied Toast

    private var copiedToast: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Copied to clipboard")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 8)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("Loading QR code…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            // Show operation selection even when there's an error (for "select operation" error)
            if !viewModel.activeTodayOperations.isEmpty {
                errorViewWithOperationSelection(message: error)
            } else {
                errorView(message: error)
            }
        } else if let value = viewModel.qrValue {
            qrView(value: value)
        } else {
            errorView(message: "QR code unavailable.")
        }
    }

    private func qrView(value: String) -> some View {
        VStack(spacing: Spacing.md) {
            if !viewModel.responderName.isEmpty {
                Text(viewModel.responderName)
                    .font(.heading3)
            }

            // Operation selection - always show if operations are available
            if !viewModel.activeTodayOperations.isEmpty {
                operationSelectionCard
            }

            CardContainer {
                QRCodeView(value: value, size: 260)
            }

            Button {
                UIPasteboard.general.string = value
                showCopiedToast = true
                Haptics.light()

                // Hide toast after 2 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    showCopiedToast = false
                }
            } label: {
                HStack {
                    Image(systemName: "doc.on.doc")
                    Text("Copy QR Code")
                }
                .font(.subheadline)
                .foregroundColor(.appPrimary)
            }

            Text("Present this QR code at the kiosk.")
                .font(.bodyRegular)
                .foregroundColor(.textSecondary)

            if let expiresAt = viewModel.expiresAt {
                Text("Valid until \(format(date: expiresAt))")
                    .font(.captionText)
                    .foregroundColor(.textSecondary)
            }

            Spacer()
        }
        .padding(Spacing.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary.ignoresSafeArea())
    }

    private var operationSelectionCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Operation")
                    .font(.heading4)

                if let selected = session.selectedOperation {
                    Text(selected.name)
                        .font(.bodyRegular)
                } else {
                    Text("Select operation")
                        .font(.bodyRegular)
                        .foregroundColor(.textSecondary)
                }

                Menu {
                    ForEach(viewModel.activeTodayOperations) { operation in
                        Button {
                            session.selectedOperation = operation
                            Task { await viewModel.refresh() }
                        } label: {
                            HStack {
                                Text(operation.name)
                                if session.selectedOperation?.id == operation.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text("Change Operation")
                            .font(.bodyRegular)
                            .foregroundColor(.appPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.appPrimary)
                    }
                    .padding(Spacing.sm)
                    .background(Color.appPrimary.opacity(0.1))
                    .cornerRadius(CornerRadius.md)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func errorViewWithOperationSelection(message: String) -> some View {
        VStack(spacing: Spacing.lg) {
            Text("Select Operation")
                .font(.heading3)
                .foregroundColor(.textPrimary)

            operationSelectionCard

            Text(message)
                .font(.bodyRegular)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.lg)

            Spacer()
        }
        .padding(Spacing.screenPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary.ignoresSafeArea())
    }

    private func errorView(message: String) -> some View {
        EmptyStateView(
            icon: "exclamationmark.triangle.fill",
            message: message,
            actionTitle: "Retry",
            action: { Task { await viewModel.load() } }
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
