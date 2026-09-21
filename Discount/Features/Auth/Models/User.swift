//
//  User.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let email: String
    let role: String
    let interests: [String]
    let latitude: Double
    let longitude: Double
    let notifyNearby: Bool
    let notifyInterests: Bool
    let notifyFavorites: Bool
    let notificationRadius: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case role
        case interests
        case latitude
        case longitude
        case notifyNearby = "notify_nearby"
        case notifyInterests = "notify_interests"
        case notifyFavorites = "notify_favorites"
        case notificationRadius = "notification_radius"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
