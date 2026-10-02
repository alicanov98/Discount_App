//
//  HomeViewModel.swift
//  Discount
//
//  Created by Malik Alijanov on 21.09.26.
//

import Foundation
import Observation

struct HomeCampaignSection: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let query: CampaignQuery
    var campaigns: [Campaign] = []
    var error: String?
}

@MainActor
@Observable
final class HomeViewModel {
    private let sessionStore: SessionStore
    private let homeRepository: any HomeRepositoryProtocol
    private(set) var state: ViewState = .idle
    private(set) var categories: [CampaignCategory] = []
    private(set) var sections: [HomeCampaignSection] = []
    private(set) var errorMessage: String?
    var user: User? {
        sessionStore.currentUser
    }

    var isLoading: Bool {
        state == .loading
    }

    init(sessionStore: SessionStore, homeRepository: any HomeRepositoryProtocol) {
        self.sessionStore = sessionStore
        self.homeRepository = homeRepository
    }

    func load() async {
        guard !isLoading else {
            return
        }
        state = .loading
        errorMessage = nil
        defer {
            state = sections.isEmpty ? .empty : .loaded
        }
        do {
            let profile: User
            do {
                profile = try await homeRepository.me()

            } catch NetworkError.unauthorized {
                try await sessionStore.refresh()
                profile = try await homeRepository.me()
            }
            sessionStore.currentUser = profile

        } catch {
            if Task.isCancelled {
                return
            }
            errorMessage = error.localizedDescription
        }
        do {
            categories = try await homeRepository.categories()

        } catch {
            if Task.isCancelled {
                return
            }
            errorMessage = error.localizedDescription
        }
        let geo = CampaignQuery(latitude: user?.latitude, longitude: user?.longitude, limit: 3)
        var featured = geo
        featured.isPro = true
        var best = geo
        best.sort = .highestDiscount
        var ending = geo
        ending.sort = .endingSoon
        sections = [
            .init(
                id: "featured",
                title: "Ön sıradakı fürsətlər",
                subtitle: "Xüsusi PRO təklifləri",
                query: featured
            ),
            .init(
                id: "best",
                title: "Daha çox qənaət et",
                subtitle: "Ən yüksək endirimləri kəşf et",
                query: best
            ),
            .init(
                id: "ending",
                title: "Son fürsəti qaçırma",
                subtitle: "Bitmək üzrə olan kampaniyalar",
                query: ending
            ),
            .init(
                id: "latest",
                title: "Təzə-təzə gəldi",
                subtitle: "Ən son əlavə olunan təkliflər",
                query: geo
            )
        ]
        if geo.latitude != nil, geo.longitude != nil {
            var nearby = geo
            nearby.radius = 5
            sections.insert(
                .init(
                    id: "nearby",
                    title: "Bir addımlığında",
                    subtitle: "Hesabındakı məkanın 5 km ətrafında",
                    query: nearby
                ),
                at: 1
            )
        }
        for category in categories where user?.interests.contains(category.slug) == true {
            var query = geo
            query.categoryID = category.id
            sections.append(
                .init(
                    id: "interest-\(category.id)",
                    title: "Sənin üçün: \(category.displayName)",
                    subtitle: "Maraqlarına uyğun təkliflər",
                    query: query
                )
            )
        }
        for index in sections.indices {
            do {
                sections[index].campaigns =
                    try await homeRepository
                        .campaigns(sections[index].query).data

            } catch {
                if Task.isCancelled {
                    return
                }
                sections[index].error = error.localizedDescription
            }
        }
    }
}
