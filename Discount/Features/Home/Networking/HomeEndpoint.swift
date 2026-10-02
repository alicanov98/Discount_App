//
//  HomeEndpoint.swift
//  Discount
//
//  Created by Malik Alijanov on 21.09.26.
//

import Foundation

enum HomeEndpoint: Endpoint {
    case me
    case categories
    case campaigns(CampaignQuery)
    case campaign(Int)
    case favorites(page: Int)
    case favorite(id: Int, saved: Bool)
    var path: String {
        switch self {
        case .me: "users/me"
        case .categories: "categories"
        case .campaigns: "campaigns"
        case let .campaign(id): "campaigns/\(id)"
        case .favorites: "users/me/favorites"
        case let .favorite(id, _): "campaigns/\(id)/favorite"
        }
    }

    var method: HTTPMethod {
        switch self {
        case let .favorite(_, saved): saved ? .post : .delete
        default: .get
        }
    }

    var requiresAuthorization: Bool {
        switch self {
        case .categories, .campaigns, .campaign: false
        default: true
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .campaigns(query): query.queryItems
        case let .favorites(page): [
                .init(name: "page", value: String(page)),
                .init(name: "limit", value: "100"),
            ]
        default: []
        }
    }
}


