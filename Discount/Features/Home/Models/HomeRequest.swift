//
//  HomeRequest.swift
//  Discount
//
//  Created by Malik Alijanov on 21.09.26.
//

import Foundation

enum CampaignSort: String, CaseIterable, Identifiable {
    case newest
    case highestDiscount = "highest_discount"
    case endingSoon = "ending_soon"
    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .newest: "Ən yenilər"
        case .highestDiscount: "Ən yüksək endirim"
        case .endingSoon: "Bitmək üzrə"
        }
    }
}

struct CampaignQuery: Hashable {
    var search = ""
    var categoryID: Int?
    var sort: CampaignSort = .newest
    var isPro: Bool?
    var latitude: Double?
    var longitude: Double?
    var radius: Double?
    var page = 1
    var limit = 20

    var queryItems: [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "sort", value: sort.rawValue),
        ]
        let text = String(
            search.trimmingCharacters(
            in: .whitespacesAndNewlines).prefix(160)
            )
        if !text.isEmpty {
            items.append(.init(name: "search", value: text))
        }
        if let categoryID {
            items.append(.init(name: "category_id", value: String(categoryID)))
        }
        if let isPro {
            items.append(.init(name: "is_pro", value: String(isPro)))
        }
        if let latitude, let longitude {
            items.append(.init(name: "latitude", value: String(latitude)))
            items.append(.init(name: "longitude", value: String(longitude)))
            if let radius {
                items.append(.init(name: "radius", value: String(radius)))
            }
        }
        return items
    }
}
