//
//  PersonnelListViewModel.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class PersonnelRosterViewModel: ObservableObject {

    enum FilterType: String, CaseIterable, Identifiable {
        case all = "All"
        case checkedIn = "In Building"
        case checkedOut = "Checked Out"
        case registered = "All Registered"

        var id: String { rawValue }
    }

    struct PersonnelRow: Identifiable, Equatable {
        let id: UUID
        let name: String
        let role: String
        let isActive: Bool
        let isPresent: Bool
        let hasCheckedOut: Bool
        let employer: String?
        let position: String?
    }

    // MARK: - Published UI State

    @Published private(set) var allPersonnel: [PersonnelRow] = []
    @Published private(set) var filteredPersonnel: [PersonnelRow] = []
    @Published var selectedFilter: FilterType = .all {
        didSet { applyFilter() }
    }
    @Published var searchText: String = "" {
        didSet { applyFilter() }
    }
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // Delete confirmation state
    @Published var personToDelete: PersonnelRow?
    @Published var showDeleteConfirmation: Bool = false

    // MARK: - Dependencies

    private let usersRepository: UsersRepository
    private let checkInService: CheckInService
    private let cache: CacheService
    private let realtimeManager = RealtimeManager.shared

    // Realtime
    private var usersChannelId: String?
    private var checkInsChannelId: String?
    private var presentIds: Set<UUID> = []
    private var checkedOutIds: Set<UUID> = []

    // MARK: - Init

    init(
        usersRepository: UsersRepository = UsersRepository(),
        checkInService: CheckInService = CheckInService(),
        cache: CacheService = .shared
    ) {
        self.usersRepository = usersRepository
        self.checkInService = checkInService
        self.cache = cache
    }

    // MARK: - Public API

    func load() async {
        resetError()
        isLoading = true

        do {
            let users = try await usersRepository.fetchAllUsers()
            let openCheckIns = try await checkInService.fetchOpenCheckIns()
            let allCheckIns = try await checkInService.fetchAllCheckIns()

            presentIds = Set(openCheckIns.map { $0.userId })
            checkedOutIds = Set(allCheckIns.filter { $0.checkoutTime != nil }.map { $0.userId })

            allPersonnel = buildPersonnelRows(
                from: users,
                presentIds: presentIds,
                checkedOutIds: checkedOutIds
            )
            applyFilter()
        } catch {
            // Fall back to cached data
            await loadFromCache()
        }

        isLoading = false
    }

    // MARK: - Realtime

    func startRealtimeUpdates() async {
        // Initial load
        await load()

        // Subscribe to user changes
        usersChannelId = await realtimeManager.subscribe(
            to: "users",
            onInsert: { [weak self] (newUser: User) in
                self?.handleUserInsert(newUser)
            },
            onUpdate: { [weak self] (updated: User) in
                self?.handleUserUpdate(updated)
            },
            onDelete: { [weak self] (deleted: User) in
                self?.handleUserDelete(deleted)
            }
        )

        // Subscribe to check-in changes (for presence status)
        checkInsChannelId = await realtimeManager.subscribe(
            to: "checkin_log",
            onInsert: { [weak self] (newCheckIn: CheckIn) in
                self?.handleCheckInInsert(newCheckIn)
            },
            onUpdate: { [weak self] (updated: CheckIn) in
                self?.handleCheckInUpdate(updated)
            },
            onDelete: { [weak self] (deleted: CheckIn) in
                self?.handleCheckInDelete(deleted)
            }
        )
    }

    func stopRealtimeUpdates() async {
        if let channelId = usersChannelId {
            await realtimeManager.unsubscribe(channelId: channelId)
            usersChannelId = nil
        }
        if let channelId = checkInsChannelId {
            await realtimeManager.unsubscribe(channelId: channelId)
            checkInsChannelId = nil
        }
    }

    private func handleUserInsert(_ user: User) {
        guard user.isActive else { return }

        let newRow = PersonnelRow(
            id: user.id,
            name: user.fullName,
            role: user.role,
            isActive: user.isActive,
            isPresent: presentIds.contains(user.id),
            hasCheckedOut: checkedOutIds.contains(user.id),
            employer: user.employer,
            position: user.credentialLevel
        )

        allPersonnel.append(newRow)
        allPersonnel.sort { lhs, rhs in
            if lhs.name.split(separator: " ").last == rhs.name.split(separator: " ").last {
                return lhs.name < rhs.name
            }
            return (lhs.name.split(separator: " ").last ?? "") < (rhs.name.split(separator: " ").last ?? "")
        }
        applyFilter()
    }

    private func handleUserUpdate(_ user: User) {
        if let index = allPersonnel.firstIndex(where: { $0.id == user.id }) {
            allPersonnel[index] = PersonnelRow(
                id: user.id,
                name: user.fullName,
                role: user.role,
                isActive: user.isActive,
                isPresent: presentIds.contains(user.id),
                hasCheckedOut: checkedOutIds.contains(user.id),
                employer: user.employer,
                position: user.credentialLevel
            )
            applyFilter()
        } else if user.isActive {
            // User was made active, add them
            handleUserInsert(user)
        }
    }

    private func handleUserDelete(_ user: User) {
        allPersonnel.removeAll { $0.id == user.id }
        presentIds.remove(user.id)
        checkedOutIds.remove(user.id)
        applyFilter()
    }

    private func handleCheckInInsert(_ checkIn: CheckIn) {
        // User checked in - mark as present
        presentIds.insert(checkIn.userId)

        // Update their row if they exist
        if let index = allPersonnel.firstIndex(where: { $0.id == checkIn.userId }) {
            var updatedRow = allPersonnel[index]
            allPersonnel[index] = PersonnelRow(
                id: updatedRow.id,
                name: updatedRow.name,
                role: updatedRow.role,
                isActive: updatedRow.isActive,
                isPresent: true,
                hasCheckedOut: updatedRow.hasCheckedOut,
                employer: updatedRow.employer,
                position: updatedRow.position
            )
            applyFilter()
        }
    }

    private func handleCheckInUpdate(_ checkIn: CheckIn) {
        if checkIn.checkoutTime != nil {
            // User checked out
            presentIds.remove(checkIn.userId)
            checkedOutIds.insert(checkIn.userId)
        } else {
            // User checked in (or checkout was cleared)
            presentIds.insert(checkIn.userId)
        }

        // Update their row
        if let index = allPersonnel.firstIndex(where: { $0.id == checkIn.userId }) {
            var updatedRow = allPersonnel[index]
            allPersonnel[index] = PersonnelRow(
                id: updatedRow.id,
                name: updatedRow.name,
                role: updatedRow.role,
                isActive: updatedRow.isActive,
                isPresent: presentIds.contains(checkIn.userId),
                hasCheckedOut: checkedOutIds.contains(checkIn.userId),
                employer: updatedRow.employer,
                position: updatedRow.position
            )
            applyFilter()
        }
    }

    private func handleCheckInDelete(_ checkIn: CheckIn) {
        // Check-in record deleted
        presentIds.remove(checkIn.userId)

        // Update their row
        if let index = allPersonnel.firstIndex(where: { $0.id == checkIn.userId }) {
            var updatedRow = allPersonnel[index]
            allPersonnel[index] = PersonnelRow(
                id: updatedRow.id,
                name: updatedRow.name,
                role: updatedRow.role,
                isActive: updatedRow.isActive,
                isPresent: false,
                hasCheckedOut: updatedRow.hasCheckedOut,
                employer: updatedRow.employer,
                position: updatedRow.position
            )
            applyFilter()
        }
    }

    func deleteUser() async {
        guard let person = personToDelete else { return }

        do {
            try await usersRepository.deleteUser(userId: person.id)

            // Remove from local list
            allPersonnel.removeAll { $0.id == person.id }
            applyFilter()

            personToDelete = nil
        } catch {
            errorMessage = "Failed to delete user: \(mapErrorMessage(error))"
        }
    }

    // MARK: - Cache Fallback

    private func loadFromCache() async {
        do {
            let cachedUsers: [LocalUser] = try await cache.load(forKey: CacheService.CacheKey.users)
            let cachedCheckIns: [LocalCheckIn] = try await cache.load(forKey: CacheService.CacheKey.checkIns)

            // Determine who's currently checked in (no checkout time)
            let presentIds = Set(cachedCheckIns.filter { $0.checkoutTime == nil }.map { $0.userId })
            let checkedOutIds = Set(cachedCheckIns.filter { $0.checkoutTime != nil }.map { $0.userId })

            // Convert to API models
            let apiUsers = cachedUsers.map { $0.toAPIModel() }

            allPersonnel = buildPersonnelRows(
                from: apiUsers,
                presentIds: presentIds,
                checkedOutIds: checkedOutIds
            )
            applyFilter()

            // Show offline indicator
            if !allPersonnel.isEmpty {
                errorMessage = "Showing cached data (offline)"
            } else {
                errorMessage = "No cached personnel data available"
            }
        } catch {
            errorMessage = mapErrorMessage(error)
        }
    }

    private func buildPersonnelRows(
        from users: [User],
        presentIds: Set<UUID>,
        checkedOutIds: Set<UUID>
    ) -> [PersonnelRow] {
        let activeUsers = users.filter { $0.isActive }
        let sorted = activeUsers.sorted { lhs, rhs in
            if lhs.lastName == rhs.lastName {
                return lhs.firstName < rhs.firstName
            }
            return lhs.lastName < rhs.lastName
        }

        return sorted.map { user in
            PersonnelRow(
                id: user.id,
                name: user.fullName,
                role: user.role,
                isActive: user.isActive,
                isPresent: presentIds.contains(user.id),
                hasCheckedOut: checkedOutIds.contains(user.id),
                employer: user.employer,
                position: user.credentialLevel
            )
        }
    }

    private func applyFilter() {
        var result: [PersonnelRow]

        switch selectedFilter {
        case .all:
            // Show everyone who is currently checked in
            result = allPersonnel.filter { $0.isPresent }

        case .checkedIn:
            // Same as .all - people currently in the building
            result = allPersonnel.filter { $0.isPresent }

        case .checkedOut:
            // People who have checked out (not currently present but have checked out before)
            result = allPersonnel.filter { !$0.isPresent && $0.hasCheckedOut }

        case .registered:
            // All registered users regardless of check-in status
            result = allPersonnel
        }

        // Apply search filter
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()
            result = result.filter { person in
                person.name.lowercased().contains(query) ||
                person.role.lowercased().contains(query) ||
                person.employer?.lowercased().contains(query) == true ||
                person.position?.lowercased().contains(query) == true
            }
        }

        filteredPersonnel = result
    }

    // MARK: - Helpers

    private func resetError() {
        errorMessage = nil
    }

    private func mapErrorMessage(_ error: Error) -> String {
        if let appError = error as? AppError {
            return appError.localizedDescription
        }
        return error.localizedDescription
    }
}
