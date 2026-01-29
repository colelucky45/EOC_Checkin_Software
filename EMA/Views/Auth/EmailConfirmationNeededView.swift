//
//  EmailConfirmationNeededView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

struct EmailConfirmationNeededView: View {

    @EnvironmentObject private var sessionManager: SessionManager
    let email: String

    // MARK: - Body

    var body: some View {
        VStack(spacing: 32) {

            Spacer()

            icon

            header

            message

            instructionsCard

            backToLoginButton

            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary.ignoresSafeArea())
    }

    // MARK: - Icon

    private var icon: some View {
        Image(systemName: "envelope.badge.shield.half.filled")
            .font(.system(size: 64))
            .foregroundColor(.accentColor)
            .symbolRenderingMode(.hierarchical)
    }

    // MARK: - Header

    private var header: some View {
        Text("Email Confirmation Required")
            .font(.heading1)
            .multilineTextAlignment(.center)
    }

    // MARK: - Message

    private var message: some View {
        VStack(spacing: 12) {
            Text("We sent a confirmation email to:")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            Text(email)
                .font(.heading4)
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Instructions Card

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Next Steps:")
                .font(.heading4)
                .foregroundColor(.textPrimary)

            instructionStep(
                number: "1",
                text: "Check your email inbox (and spam folder)"
            )

            instructionStep(
                number: "2",
                text: "Click the confirmation link in the email"
            )

            instructionStep(
                number: "3",
                text: "Return to this app and log in"
            )
        }
        .padding(20)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }

    private func instructionStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.heading3)
                .foregroundColor(.accentColor)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.accentColor.opacity(0.15)))

            Text(text)
                .font(.body)
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Back to Login Button

    private var backToLoginButton: some View {
        SecondaryButton(
            title: "Back to Login",
            action: {
                // Reset email confirmation state
                Task {
                    await MainActor.run {
                        sessionManager.clearEmailConfirmationState()
                    }
                }
            }
        )
    }
}
