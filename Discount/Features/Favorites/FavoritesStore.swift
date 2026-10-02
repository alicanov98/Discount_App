//
//  FavoritesView.swift
//  Discount
//
//  Created by Malik Alijanov on 02.10.26.
//

import Foundation
import Observation

@MainActor
@Observable
final class FavoritesStore {
    private let repository: any HomeRepositoryProtocol
    private let sessionStore: SessionStore
    private(set) var campaigns: [Campaign] = []
    private(set) var isLoading = false
    private(set) var pendingIDs: Set<Int> = []
    private(set) var hasLoaded = false

    private var ownerID: Int?
    var errorMessage: String?
    var canSave: Bool {
        sessionStore.currentUser?.role == "user"
    }

    init(repository: any HomeRepositoryProtocol, sessionStore: SessionStore) {
        self.repository = repository
        self.sessionStore = sessionStore
    }

    func contains(_ id: Int) -> Bool {
        ownerID == sessionStore.currentUser?.id
            && campaigns.contains {
                $0.id == id
            }
    }

    func load() async {
        let accountID = sessionStore.currentUser?.id
        if ownerID != accountID {
            campaigns = []
            hasLoaded = false
            ownerID = accountID
        }
        guard canSave, !isLoading, pendingIDs.isEmpty else {
            return
        }
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
        }
        do {
            var items: [Campaign] = []
            var page = 1
            while true {
                let response = try await repository.favorites(page: page)
                items.append(contentsOf: response.data)
                if page >= response.meta.totalPages {
                    break
                }
                page += 1
            }
            try Task.checkCancellation()
            guard accountID == sessionStore.currentUser?.id else {
                return
            }
            campaigns = items
            hasLoaded = true

        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
            }
        }
    }

    func toggle(_ campaign: Campaign) async {
        guard canSave, ownerID == sessionStore.currentUser?.id, hasLoaded, !isLoading,
            !pendingIDs.contains(campaign.id)
        else {
            return
        }
        pendingIDs.insert(campaign.id)
        errorMessage = nil
        defer {
            pendingIDs.remove(campaign.id)
        }
        let save = !contains(campaign.id)
        do {
            try await repository.setFavorite(id: campaign.id, saved: save)
            if save {
                campaigns.insert(campaign, at: 0)

            } else {
                campaigns.removeAll {
                    $0.id == campaign.id
                }
            }

        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
            }
        }
    }
}
