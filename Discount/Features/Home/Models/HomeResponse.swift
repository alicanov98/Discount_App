//
//  HomeResponse.swift
//  Discount
//
//  Created by Malik Alijanov on 21.09.26.
//

import Foundation


struct MeResponseData:Codable {
    let data: User
}

struct HomeDataResponse: Decodable {
     let data: Value
    }
struct CampaignPage: Decodable {
    let data: [Campaign]
    let meta: CampaignPagination
}

struct CampaignPagination: Decodable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
    enum CodingKeys: String, CodingKey {
        case page, limit, total
        case totalPages = "total_pages"
    }
}

struct CampaignCategory: Decodable, Identifiable, Hashable {
    let id: Int
    let slug: String
    let name: String
    var displayName: String {
        switch slug {
        case "fashion": "Moda"
        case "electronics": "Elektronika"
        case "food": "Yemək və içki"
        case "beauty": "Gözəllik"
        case "sports": "İdman"
        case "entertainment": "Əyləncə"
        case "home": "Ev və yaşam"
        case "travel": "Səyahət"
        case "market": "Market"
        default: name
        }
    }

    var symbol: String {
        switch slug {
        case "fashion": "tshirt"
        case "electronics": "headphones"
        case "food": "fork.knife"
        case "beauty": "sparkles"
        case "sports": "dumbbell"
        case "entertainment": "ticket"
        case "home": "house"
        case "travel": "airplane"
        case "market": "basket"
        default: "tag"
        }
    }
}

struct Campaign: Decodable, Identifiable, Hashable {
    let id: Int
    let businessID: Int
    let businessName: String
    let title: String
    let description: String
    let imageURL: String?
    let terms: String?
    let categoryID: Int
    let discountType: String
    let discountValue: Double
    let startDate: String
    let endDate: String
    let latitude: Double
    let longitude: Double
    let address: String
    let status: String
    let isPro: Bool
    let isBoosted: Bool
    let distance: Double?

    var discountLabel: String {
        let value = discountValue.formatted(
            .number.precision(
                .fractionLength(0 ... 2)
            ))
        switch discountType {
        case "percentage": return "\(value)% endirim"
        case "fixed": return "\(value) ₼ endirim"
        default: return "Xüsusi təklif"
        }
    }

    static func displayDate(_ value: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: value)
         else { 
            return value 
            }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "az_AZ")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, terms, latitude, longitude, address, status, distance
        case businessID = "business_id", businessName = "business_name"
        case imageURL = "image_url", categoryID = "category_id"
        case discountType = "discount_type", discountValue = "discount_value"
        case startDate = "start_date", endDate = "end_date"
        case isPro = "is_pro", isBoosted = "is_boosted"
    }
}
