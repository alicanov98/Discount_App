//
//  HomeRepository.swift
//  Discount
//
//  Created by Malik Alijanov on 21.09.26.
//

import Foundation

protocol HomeRepositoryProtocol {
    func me () async throws -> User
    func categories() async throws -> [CampaignCategory]
    func campaigns(_ query: CampaignQuery) async throws -> CampaignPage
    func campaign(id: Int) async throws -> Campaign
    func favorites(page: Int) async throws -> CampaignPage
    func setFavorite(id: Int, saved: Bool) async throws
}

final class HomeRepository: HomeRepositoryProtocol {
    private let networkService: any NetworkServiceProtocol

    init(networkService: any NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func me() async throws -> User {
        try await networkService.request(
        HomeEndpoint.me, 
        responseType: MeResponseData.self).data
    }

    func categories() async throws -> [CampaignCategory] {
        try await networkService.request(
            HomeEndpoint.categories,
            responseType: HomeDataResponse<[CampaignCategory]>.self).data
    }

    func campaigns(_ query: CampaignQuery) async throws -> CampaignPage {
        try await networkService.request(
         HomeEndpoint.campaigns(query),
         responseType: CampaignPage.self)
    }

    func campaign(id: Int) async throws -> Campaign {
        try await networkService.request(
            HomeEndpoint.campaign(id),
            responseType: HomeDataResponse<Campaign>.self).data
    }

    func favorites(page: Int) async throws -> CampaignPage {
        try await networkService.request(
        HomeEndpoint.favorites(page: page), 
        responseType: CampaignPage.self)
    }

    func setFavorite(id: Int, saved: Bool) async throws {
        try await networkService.request(
        HomeEndpoint.favorite(id: id, saved: saved))
    }
}
