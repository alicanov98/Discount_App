//
//  SearchView.swift
//  Discount
//
//  Created by Malik Alijanov on 02.10.26.
//

@testable import Discount
import Foundation
import Testing

@MainActor
struct CampaignTests {
    @Test func queryOmitsInvalidGeoAndBlankSearch() {
        let query = CampaignQuery(search: "  ", isPro: true, latitude: 40.4, radius: 5)
        let items = Dictionary(
            uniqueKeysWithValues: query.queryItems
                .map {
                    ($0.name, $0.value ?? "")
                }
        )
        #expect(items["search"] == nil)
        #expect(items["latitude"] == nil)
        #expect(items["radius"] == nil)
        #expect(items["is_pro"] == "true")
        let valid = CampaignQuery(
            search: "  qəhvə & çay  ",
            categoryID: 3,
            latitude: 40.4,
            longitude: 49.8,
            radius: 5
        )
        #expect(
            valid.queryItems.first {
                $0.name == "search"
            }?
                .value == "qəhvə & çay"
        )
        #expect(
            valid.queryItems.first {
                $0.name == "longitude"
            }?
                .value == "49.8"
        )
    }

    @Test func backendCampaignDecodesNullImageAndOptionalDistance() throws {
        let campaign = try JSONDecoder().decode(Campaign.self, from: fixture)
        #expect(campaign.businessName == "Coffee House")
        #expect(campaign.imageURL == nil)
        #expect(campaign.distance == nil)
        #expect(campaign.discountLabel == "25% endirim")
        #expect(campaign.isPro)
    }

    @Test func paginationRetainsFilterAndRemovesDuplicateCards() async throws {
        let repository = FakeCampaignRepository()
        let campaign = try JSONDecoder().decode(Campaign.self, from: fixture)
        repository.pageItems = [campaign]
        let model = CampaignListViewModel(repository: repository)
        let query = CampaignQuery(search: "qəhvə", categoryID: 3, sort: .highestDiscount)
        await model.load(query)
        #expect(model.canLoadMore)
        await model.load(CampaignQuery(), more: true)
        #expect(repository.queries.map(\.page) == [1, 2])
        #expect(repository.queries.last?.search == "qəhvə")
        #expect(repository.queries.last?.categoryID == 3)
        #expect(model.campaigns.count == 1)
        #expect(!model.canLoadMore)
    }

    @Test func oldSearchCannotOverwriteNewSearch() async throws {
        let repository = FakeCampaignRepository()
        repository.pageItems = try [JSONDecoder().decode(Campaign.self, from: fixture)]
        repository.suspendOldSearch = true
        let model = CampaignListViewModel(repository: repository)
        let old = Task {
            await model.load(CampaignQuery(search: "old"))
        }
        while repository.oldContinuation == nil {
            await Task.yield()
        }
        await model.load(CampaignQuery(search: "new"))
        repository.oldContinuation?
            .resume(
                returning: CampaignPage(
                    data: [],
                    meta: .init(page: 1, limit: 20, total: 0, totalPages: 0)
                )
            )
        await old.value
        #expect(model.campaigns.count == 1)
        #expect(model.total == 2)
    }

    @Test func failedFavoriteRequestKeepsServerConfirmedState() async throws {
        let repository = FakeCampaignRepository()
        let session = SessionStore(
            authRepository: AuthRepository(networkService: UnusedNetworkService()),
            tokenStore: MemoryTokens()
        )
        session.currentUser = User.mock
        let store = FavoritesStore(repository: repository, sessionStore: session)
        let campaign = try JSONDecoder().decode(Campaign.self, from: fixture)
        await store.load()
        repository.failFavorite = true
        await store.toggle(campaign)
        #expect(!store.contains(campaign.id))
        #expect(store.errorMessage != nil)
        repository.failFavorite = false
        await store.toggle(campaign)
        #expect(store.contains(campaign.id))
        repository.failFavorite = true
        await store.toggle(campaign)
        #expect(store.contains(campaign.id))
        #expect(store.pendingIDs.isEmpty)
    }

    @Test func failedHomeSectionDoesNotHideOtherSections() async throws {
        let repository = FakeCampaignRepository()
        repository.pageItems = try [JSONDecoder().decode(Campaign.self, from: fixture)]
        repository.failPro = true
        let session = SessionStore(
            authRepository: AuthRepository(networkService: UnusedNetworkService()),
            tokenStore: MemoryTokens()
        )
        let model = HomeViewModel(sessionStore: session, homeRepository: repository)
        await model.load()
        #expect(
            model.sections.first {
                $0.id == "featured"
            }?
                .error != nil
        )
        #expect(
            model.sections.first {
                $0.id == "latest"
            }?
                .campaigns.count == 1
        )
        #expect(
            model.sections.contains {
                $0.id == "nearby"
            }
        )
        #expect(!model.isLoading)
    }
}

private let fixture = Data(
    """
    {"id":1,"business_id":2,"business_name":"Coffee House","title":"Qəhvə endirimi","description":"Bütün qəhvələrə endirim","image_url":null,"terms":null,"category_id":3,"discount_type":"percentage","discount_value":25,"start_date":"2026-10-01","end_date":"2026-10-31","latitude":40.4,"longitude":49.8,"address":"Bakı","status":"active","is_pro":true,"is_boosted":false}
    """
    .utf8
)

@MainActor
private final class FakeCampaignRepository: HomeRepositoryProtocol {
    var queries: [CampaignQuery] = []
    var pageItems: [Campaign] = []
    var failFavorite = false
    var failPro = false
    var suspendOldSearch = false
    var oldContinuation: CheckedContinuation<CampaignPage, Never>?

    func me() async throws -> User {
        User.mock
    }

    func categories() async throws -> [CampaignCategory] {
        []
    }

    func campaigns(_ query: CampaignQuery) async throws -> CampaignPage {
        queries.append(query)
        if failPro && query.isPro == true {
            throw URLError(.badServerResponse)
        }
        if suspendOldSearch && query.search == "old" {
            return await withCheckedContinuation {
                oldContinuation = $0
            }
        }
        return CampaignPage(
            data: pageItems,
            meta: .init(page: query.page, limit: 20, total: 2, totalPages: 2)
        )
    }

    func campaign(id _: Int) async throws -> Campaign {
        try JSONDecoder().decode(Campaign.self, from: fixture)
    }

    func favorites(page: Int) async throws -> CampaignPage {
        CampaignPage(data: [], meta: .init(page: page, limit: 100, total: 0, totalPages: 0))
    }

    func setFavorite(id _: Int, saved _: Bool) async throws {
        if failFavorite {
            throw URLError(.notConnectedToInternet)
        }
    }
}

private final class MemoryTokens: TokenStore {
    var accessToken: String?
    var refreshToken: String?

    func saveTokens(accessToken: String, refreshToken: String) throws {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func clearTokens() throws {
        accessToken = nil
        refreshToken = nil
    }
}

private struct UnusedNetworkService: NetworkServiceProtocol {
    func request<Response: Decodable>(
        _: any Endpoint,
        responseType _: Response.Type
    ) async throws -> Response {
        throw URLError(.unsupportedURL)
    }

    func request(_: any Endpoint) async throws {
        throw URLError(.unsupportedURL)
    }
}
