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
    private static let heroCardLimit = 10
    private static let sectionCardLimit = 2
    private let sessionStore: SessionStore
    private let homeRepository: any HomeRepositoryProtocol
    private let locationService = HomeLocationService()
    private var headerDate = Date()
    private(set) var state: ViewState = .idle
    private(set) var categories: [CampaignCategory] = []
    private(set) var sections: [HomeCampaignSection] = []
    private(set) var errorMessage: String?
    private(set) var hasLoaded = false
    var user: User? {
        sessionStore.currentUser
    }

    var isLoading: Bool {
        state == .loading
    }

    var showsInitialLoading: Bool {
        !hasLoaded && isLoading
    }

    var greeting: String {
        HomeHeaderFormatting.greeting(name: user?.name, date: headerDate)
    }

    var locationTitle: String {
        locationService.title
    }

    func monitorHeader() async {
        headerDate = Date()
        locationService.start()
        defer { locationService.stop() }
        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(60))
            } catch { return }
            headerDate = Date()
        }
    }

    var heroCampaigns: [Campaign] {
        Array((sections.first { $0.id == "latest" }?.campaigns ?? []).prefix(Self.heroCardLimit))
    }

    var visibleSections: [HomeCampaignSection] {
        sections.filter { $0.id != "latest" && !$0.campaigns.isEmpty }.map { section in
            var visibleSection = section
            visibleSection.campaigns = Array(section.campaigns.prefix(Self.sectionCardLimit))
            return visibleSection
        }
    }

    func query(for category: CampaignCategory) -> CampaignQuery {
        CampaignQuery(categoryID: category.id)
    }

    init(sessionStore: SessionStore, homeRepository: any HomeRepositoryProtocol) {
        self.sessionStore = sessionStore
        self.homeRepository = homeRepository
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await load()
    }

    func load() async {
        guard !isLoading else {
            return
        }
        state = .loading
        errorMessage = nil
        defer {
            state = hasLoaded ? (sections.isEmpty ? .empty : .loaded) : .idle
        }
        var loadedCategories = categories
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
            loadedCategories = try await homeRepository.categories()

        } catch {
            if Task.isCancelled {
                return
            }
            errorMessage = error.localizedDescription
        }
        let geo = CampaignQuery(
            latitude: user?.latitude, longitude: user?.longitude, limit: Self.sectionCardLimit
        )
        var featured = geo
        featured.isPro = true
        var best = geo
        best.sort = .highestDiscount
        var ending = geo
        ending.sort = .endingSoon
        var latest = geo
        latest.limit = Self.heroCardLimit
        var loadedSections: [HomeCampaignSection] = [
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
                query: latest
            ),
        ]
        if geo.latitude != nil, geo.longitude != nil {
            var nearby = geo
            nearby.radius = 5
            loadedSections.insert(
                .init(
                    id: "nearby",
                    title: "Bir addımlığında",
                    subtitle: "Hesabındakı məkanın 5 km ətrafında",
                    query: nearby
                ),
                at: 1
            )
        }
        for category in loadedCategories where user?.interests.contains(category.slug) == true {
            var query = geo
            query.categoryID = category.id
            loadedSections.append(
                .init(
                    id: "interest-\(category.id)",
                    title: "Sənin üçün: \(category.displayName)",
                    subtitle: "Maraqlarına uyğun təkliflər",
                    query: query
                )
            )
        }
        for index in loadedSections.indices {
            do {
                loadedSections[index].campaigns =
                    try await homeRepository
                        .campaigns(loadedSections[index].query).data

            } catch {
                if Task.isCancelled {
                    return
                }
                loadedSections[index].error = error.localizedDescription
            }
        }
        guard !Task.isCancelled else { return }
        categories = loadedCategories
        sections = loadedSections
        hasLoaded = true
    }
}
