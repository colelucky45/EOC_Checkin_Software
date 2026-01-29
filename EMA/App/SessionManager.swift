//
//  SessionManager.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import Combine

// Manages authentication state, session persistence, and user identity.
@MainActor
final class SessionManager: ObservableObject, Sendable {

    // MARK: - Published Properties

    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: User?
    @Published private(set) var role: String?
    @Published private(set) var isRestoringSession: Bool = true
    @Published private(set) var needsProfileCompletion: Bool = false
    @Published private(set) var profileCompletionUserId: UUID?
    @Published private(set) var profileCompletionEmail: String?
    @Published private(set) var needsEmailConfirmation: Bool = false
    @Published private(set) var unconfirmedEmail: String?
    @Published var selectedOperation: Operation?

    // MARK: - Dependencies

    private let backend: BackendProtocol
    private let usersRepository: UsersRepository
    private let syncCoordinator: SyncCoordinator

    // MARK: - Initialization

    init(
        backend: BackendProtocol = BackendFactory.current,
        usersRepository: UsersRepository = UsersRepository(),
        syncCoordinator: SyncCoordinator? = nil
    ) {
        self.backend = backend
        self.usersRepository = usersRepository
        self.syncCoordinator = syncCoordinator ?? SyncCoordinator()
        Task {
#if DEBUG
            await clearAuthSessionForDevelopment()
#endif
            await restoreSessionIfPossible()
        }
    }

    // MARK: - Session Restore

    private func restoreSessionIfPossible() async {
        defer { isRestoringSession = false }

        do {
            guard let session = try await backend.auth.currentSession() else {
                isAuthenticated = false
                currentUser = nil
                role = nil
                return
            }

            if session.isExpired {
                Logger.log(
                    "Session expired, logging out automatically",
                    level: .info,
                    category: "SessionManager"
                )
                await logout()
                return
            }

            try await loadUserProfile(session: session)
        } catch {
            isAuthenticated = false
            currentUser = nil
            role = nil
        }
    }

    // MARK: - Login

    func login(email: String, password: String) async throws {
        needsEmailConfirmation = false
        unconfirmedEmail = nil

        do {
            let session = try await backend.auth.signIn(
                email: email,
                password: password
            )
            try await loadUserProfile(session: session)
        } catch {
            let errorMessage = error.localizedDescription.lowercased()
            if errorMessage.contains("email") &&
               (errorMessage.contains("confirm") ||
                errorMessage.contains("verify") ||
                errorMessage.contains("not confirmed")) {
                needsEmailConfirmation = true
                unconfirmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

                Logger.log(
                    "Login blocked: email not confirmed",
                    level: .info,
                    category: "SessionManager",
                    metadata: ["email": email]
                )

                throw AppError.authentication("Please confirm your email before logging in.")
            }
            throw error
        }
    }

    // MARK: - Email Confirmation State

    func clearEmailConfirmationState() {
        needsEmailConfirmation = false
        unconfirmedEmail = nil
    }

    // MARK: - Update Current User

    func updateCurrentUser(_ user: User) {
        self.currentUser = user
    }

    // MARK: - Manual Sync

    func triggerManualSync() async {
        await syncCoordinator.syncNow(reason: "Manual sync")
    }

    // MARK: - Logout

    func logout() async {
        do {
            try await backend.auth.signOut()
        } catch {
            // Ignore errors
        }

        do {
            try await syncCoordinator.reset()
        } catch {
            Logger.log(
                error: .unexpected("Failed to clear sync cache: \(error.localizedDescription)"),
                level: .warning,
                category: "SessionManager",
                context: "logout"
            )
        }

        isAuthenticated = false
        currentUser = nil
        role = nil
        selectedOperation = nil
    }

    // MARK: - Load Profile After Auth

    func loadUserProfile(session: AuthSession) async throws {
        let userId = session.userId
        let userEmail = session.email ?? ""

        do {
            let profile = try await usersRepository.fetchUser(by: userId)

            self.currentUser = profile
            self.role = profile.role
            self.isAuthenticated = true
            self.needsProfileCompletion = false
            self.profileCompletionUserId = nil
            self.profileCompletionEmail = nil

            await syncCoordinator.registerSyncSteps()
            await syncCoordinator.syncNow(reason: "Session restored")

        } catch {
            Logger.log(
                "User profile not found, needs completion",
                level: .info,
                category: "SessionManager",
                metadata: ["userId": userId.uuidString]
            )

            self.isAuthenticated = true
            self.needsProfileCompletion = true
            self.profileCompletionUserId = userId
            self.profileCompletionEmail = userEmail
            self.currentUser = nil
            self.role = nil
        }
    }

    // MARK: - Development Reset

    private func clearAuthSessionForDevelopment() async {
        do {
            try await backend.auth.signOut()
        } catch {
            // Ignore
        }

        isAuthenticated = false
        currentUser = nil
        role = nil
    }
}
