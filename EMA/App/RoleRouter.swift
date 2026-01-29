//
//  RoleRouter.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import SwiftUI

struct RoleRouter: View {

    @EnvironmentObject private var session: SessionManager

    var body: some View {
        Group {
            if session.isRestoringSession {
                LoadingView()
            } else if session.needsEmailConfirmation {
                emailConfirmationView
            } else if !session.isAuthenticated {
                authView
            } else if session.needsProfileCompletion {
                profileCompletionView
            } else {
                mainAppView
            }
        }
    }

    // MARK: - Auth Flow

    private var authView: some View {
        NavigationStack {
            LoginView(sessionManager: session)
        }
    }

    // MARK: - Email Confirmation Needed

    private var emailConfirmationView: some View {
        Group {
            if let email = session.unconfirmedEmail {
                EmailConfirmationNeededView(email: email)
            } else {
                // Fallback - should never happen
                authView
            }
        }
    }

    // MARK: - Profile Completion

    private var profileCompletionView: some View {
        Group {
            if let userId = session.profileCompletionUserId,
               let email = session.profileCompletionEmail {
                ProfileCompletionView(
                    viewModel: ProfileCompletionViewModel(
                        userId: userId,
                        userEmail: email
                    )
                )
            } else {
                // Fallback - should never happen
                LoadingView()
            }
        }
    }

    // MARK: - Role Routing

    @ViewBuilder
    private var mainAppView: some View {
        switch session.role {
        case "admin":
            AdminDashboardView()

        case "kiosk":
            KioskContainerView(session: session)

        default:
            responderTabView
        }
    }

    // MARK: - Responder Navigation

    private var responderTabView: some View {
        TabView {
            ResponderHomeView(session: session)
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            ResponderQRView(session: session)
                .tabItem {
                    Label("My QR", systemImage: "qrcode")
                }

            ResponderHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }

            ResponderProfileView(session: session)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
        }
        .ignoresSafeArea()
    }
}
