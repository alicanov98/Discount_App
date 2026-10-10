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

struct HomeDataResponse<Value: Decodable>: Decodable {
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
        case "fashion": AppLocalization.string("Moda")
        case "electronics": AppLocalization.string("Elektronika")
        case "food": AppLocalization.string("Yemək və içki")
        case "beauty": AppLocalization.string("Gözəllik")
        case "sports": AppLocalization.string("İdman")
        case "entertainment": AppLocalization.string("Əyləncə")
        case "home": AppLocalization.string("Ev və yaşam")
        case "travel": AppLocalization.string("Səyahət")
        case "market": AppLocalization.string("Market")
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
        case "percentage": return String(format: AppLocalization.string("%@%% endirim"), value)
        case "fixed": return String(format: AppLocalization.string("%@ ₼ endirim"), value)
        default: return AppLocalization.string("Xüsusi təklif")
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
        formatter.locale = Locale(identifier: UserDefaults.standard.string(forKey: "app.language") ?? "az")
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

#if DEBUG
extension Campaign {
    static let mock = mockData[0]

    static let mockData: [Campaign] = [
        Campaign(
            id: 1,
            businessID: 101,
            businessName: "Coffee House",
            title: "Bütün qəhvələrə 20% endirim",
            description: "Sevdiyin qəhvəni daha sərfəli qiymətə al.",
            imageURL: "https://m.media-amazon.com/images/I/51Z58VM9BaL._AC_SX679_.jpg",
            terms: "Endirim yalnız yerində sifarişlərə aiddir.",
            categoryID: 1,
            discountType: "percentage",
            discountValue: 20,
            startDate: "2026-10-01",
            endDate: "2026-10-31",
            latitude: 40.3713,
            longitude: 49.8374,
            address: "Bakı, Nizami küçəsi 45",
            status: "active",
            isPro: true,
            isBoosted: true,
            distance: 0.8
        ),
        Campaign(
            id: 2,
            businessID: 102,
            businessName: "Sport Store",
            title: "İdman ayaqqabılarına 30 ₼ endirim",
            description: "Seçilmiş idman ayaqqabılarında xüsusi fürsət.",
            imageURL: nil,
            terms: "100 ₼ və daha yüksək məbləğli alışlara aiddir.",
            categoryID: 2,
            discountType: "fixed",
            discountValue: 30,
            startDate: "2026-10-05",
            endDate: "2026-11-05",
            latitude: 40.4000,
            longitude: 49.8500,
            address: "Bakı, Azadlıq prospekti 88",
            status: "active",
            isPro: false,
            isBoosted: false,
            distance: 2.4
        ),
        Campaign(
            id: 3,
            businessID: 103,
            businessName: "Style Boutique",
            title: "Payız kolleksiyasına 50% endirim",
            description: "Geyim və aksesuarlarda mövsüm fürsətlərini kəşf et.",
            imageURL: nil,
            terms: "Stoklarla məhdudlaşır.",
            categoryID: 3,
            discountType: "percentage",
            discountValue: 50,
            startDate: "2026-10-01",
            endDate: "2026-10-20",
            latitude: 40.3777,
            longitude: 49.8920,
            address: "Bakı, Xətai prospekti 15",
            status: "active",
            isPro: true,
            isBoosted: false,
            distance: nil
        )
    ]
}
#endif
