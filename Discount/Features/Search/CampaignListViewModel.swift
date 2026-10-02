//
//  HomeViewModel.swift
//  Discount
//
//  Created by Malik Alijanov on 02.10.26.
//

import Foundation
import Observation

@MainActor
@Observable
final class CampaignListViewModel {
    private let repository: any HomeRepositoryProtocol

    private var generation = UUID()
    private(set) var campaigns: [Campaign] = []
    private(set) var categories: [CampaignCategory] = []
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var total = 0
    private(set) var canLoadMore = false
    private(set) var errorMessage: String?

    private var loadedQuery = CampaignQuery()

    private var page = 0

    init(repository: any HomeRepositoryProtocol) {
        self.repository = repository
    }

    func loadCategories() async {
        do {
            categories = try await repository.categories()
        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
            }
        }
    }

    func load(_ query: CampaignQuery, more: Bool = false) async {
        if more && (isLoading || !canLoadMore) {
            return
        }
        let requestID = UUID()
        generation = requestID
        isLoading = true
        errorMessage = nil
        if !more {
            campaigns = []
            total = 0
            hasLoaded = false
            canLoadMore = false
        }
        var request = more ? loadedQuery : query
        request.page = more ? page + 1 : 1
        defer {
            if generation == requestID {
                isLoading = false
            }
        }
        do {
            let result = try await repository.campaigns(request)
            guard generation == requestID, !Task.isCancelled else {
                return
            }
            if more {
                let ids = Set(campaigns.map(\.id))
                campaigns.append(
                    contentsOf: result.data.filter {
                        !ids.contains($0.id)
                    }
                )

            } else {
                campaigns = result.data
            }
            loadedQuery = request
            page = result.meta.page
            total = result.meta.total
            canLoadMore = page < result.meta.totalPages
            hasLoaded = true

        } catch {
            guard generation == requestID, !Task.isCancelled else {
                return
            }
            errorMessage = error.localizedDescription
        }
    }
}
