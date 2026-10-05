//
//  MapRepository.swift
//  Discount
//
//  Created by Malik Alijanov on 04.10.26.
//

import Foundation

struct NearbyCampaignEndpoint: Endpoint {
    let latitude: Double
    let longitude: Double
    let page: Int
    var path: String { "campaigns/nearby" }
    var method: HTTPMethod { .get }
    var requiresAuthorization: Bool { false }
    var queryItems: [URLQueryItem] {
        [
            .init(name: "latitude", value: String(latitude)),
            .init(name: "longitude", value: String(longitude)),
            .init(name: "radius", value: "5"),
            .init(name: "limit", value: "100"),
            .init(name: "page", value: String(page)),
        ]
    }
}

struct NearbyCampaignResponse: Decodable {
    let data: [Campaign]
    let meta: CampaignPagination?
}

protocol MapRepositoryProtocol {
    func nearby(latitude: Double, longitude: Double, page: Int) async throws -> NearbyCampaignResponse
}

final class MapRepository: MapRepositoryProtocol {
    private let networkService: any NetworkServiceProtocol
    init(networkService: any NetworkServiceProtocol) {
        self.networkService = networkService
    }
    func nearby(latitude: Double, longitude: Double, page: Int) async throws -> NearbyCampaignResponse {
        try await networkService.request(
            NearbyCampaignEndpoint(latitude: latitude, longitude: longitude, page: page),
            responseType: NearbyCampaignResponse.self
        )
    }
}
