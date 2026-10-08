//
//  ProfileViewModel.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    enum Operation {
        case idle
        case loading
        case savingProfile
        case savingInterests
        case loggingOut
        case deleting
    }

    private let repository: any ProfileRepositoryProtocol
    private let sessionStore: SessionStore
    private let appState: AppState

    private var savedDraft = ProfileDraft()
    private var savedInterests: Set<String> = []

    private(set) var operation: Operation = .idle
    private(set) var hasLoaded = false
    private(set) var user: User?
    private(set) var business: BusinessProfile?
    private(set) var categories: [CampaignCategory] = []
    private(set) var categoryError: String?

    var draft = ProfileDraft()
    var selectedInterests: Set<String> = []
    var errorMessage: String?
    var successMessage: String?
    var isShowingError = false

    var isBusy: Bool {
        operation != .idle
    }

    var isBusiness: Bool {
        user?.role == "business"
    }

    var hasProfileChanges: Bool {
        draft != savedDraft
    }

    var hasInterestChanges: Bool {
        selectedInterests != savedInterests
    }

    var initials: String {
        let parts = (business?.name ?? user?.name ?? "")
            .split(separator: " ")

        return parts
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }

    init(
        repository: any ProfileRepositoryProtocol,
        sessionStore: SessionStore,
        appState: AppState
    ) {
        self.repository = repository
        self.sessionStore = sessionStore
        self.appState = appState

        user = sessionStore.currentUser
    }

    func load() async {
        guard !isBusy else {
            return
        }

        if hasLoaded {
            if categories.isEmpty {
                await loadCategories()
            }

            return
        }

        operation = .loading

        defer {
            operation = .idle
        }

        do {
            let profile = try await repository.me()

            var businessProfile: BusinessProfile?

            if profile.role == "business" {
                businessProfile = try await repository.business()
            }

            try Task.checkCancellation()

            user = profile
            sessionStore.currentUser = profile
            business = businessProfile
            draft = businessProfile.map(ProfileDraft.init(business:))
                ?? ProfileDraft(user: profile)
            savedDraft = draft
            selectedInterests = Set(profile.interests)
            savedInterests = selectedInterests
            hasLoaded = true

            await loadCategories()
        } catch {
            showError(error)
        }
    }

    func loadCategories() async {
        categoryError = nil

        do {
            categories = try await repository.categories()
        } catch {
            if !Task.isCancelled {
                categoryError = error.localizedDescription
            }
        }
    }

    func toggleInterest(_ slug: String) {
        guard !isBusy else {
            return
        }

        if selectedInterests.contains(slug) {
            selectedInterests.remove(slug)
        } else {
            selectedInterests.insert(slug)
        }

        successMessage = nil
    }

    @discardableResult
    func saveProfile(
        section: ProfileSection? = nil,
        editedDraft: ProfileDraft? = nil
    ) async -> Bool {
        guard hasLoaded,
              !isBusy,
              section != .interests,
              !(isBusiness && section == .notifications)
        else {
            return false
        }

        operation = .savingProfile
        successMessage = nil

        defer {
            operation = .idle
        }

        do {
            let edited = editedDraft ?? draft

            if isBusiness {
                let request = try edited.businessRequest(section: section)
                let updated = try await repository.updateBusiness(request)

                business = updated
                draft = ProfileDraft(business: updated)
                user = user?.updatingIdentity(
                    name: updated.name,
                    email: updated.email
                )
            } else {
                let request = try edited.personalRequest(section: section)
                let updated = try await repository.update(request)

                user = updated
                draft = ProfileDraft(user: updated)
            }

            sessionStore.currentUser = user
            savedDraft = draft
            successMessage = "Profil məlumatları saxlanıldı."

            return true
        } catch {
            showError(error)
            return false
        }
    }

    @discardableResult
    func saveInterests(
        _ editedInterests: Set<String>? = nil
    ) async -> Bool {
        guard hasLoaded,
              !isBusiness,
              !isBusy
        else {
            return false
        }

        operation = .savingInterests
        successMessage = nil

        defer {
            operation = .idle
        }

        do {
            let interests = (editedInterests ?? selectedInterests).sorted()
            let updated = try await repository.updateInterests(interests)

            selectedInterests = Set(updated)
            savedInterests = selectedInterests
            user = user?.updatingIdentity(interests: updated)
            sessionStore.currentUser = user
            successMessage = "Maraqların yeniləndi."

            return true
        } catch {
            showError(error)
            return false
        }
    }

    func logout() async {
        guard !isBusy else {
            return
        }

        operation = .loggingOut

        defer {
            operation = .idle
        }

        do {
            try await sessionStore.logout()

            appState.logoutCompleted()
        } catch {
            showError(error)
        }
    }

    func deleteAccount() async {
        guard hasLoaded, !isBusy else {
            return
        }

        operation = .deleting

        defer {
            operation = .idle
        }

        do {
            try await repository.deleteAccount()

            defer {
                appState.logoutCompleted()
            }

            try sessionStore.clearSession()
        } catch {
            showError(error)
        }
    }

    private func showError(_ error: Error) {
        guard !Task.isCancelled else {
            return
        }

        errorMessage = error.localizedDescription
        isShowingError = true

        if !sessionStore.isAuthenticated {
            appState.logoutCompleted()
        }
    }
}
