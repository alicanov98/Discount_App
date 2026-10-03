//
//  ProfileEndpoint.swift
//  Discount
//
//  Created by Malik Alijanov on 03.10.26.
//

import Foundation

enum ProfileEndpoint: Endpoint {
    case me
    case update(ProfileUpdateRequest)
    case business
    case updateBusiness(BusinessUpdateRequest)
    case updateInterests([String])
    case deleteAccount
    var path: String {
        switch self {
        case .me, .update, .deleteAccount: "users/me"
        case .business, .updateBusiness: "business/me"
        case .updateInterests: "users/me/interests"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .me, .business: .get
        case .update, .updateBusiness, .updateInterests: .put
        case .deleteAccount: .delete
        }
    }

    func body() throws -> Data? {
        switch self {
        case let .update(request): try JSONEncoder().encode(request)
        case let .updateBusiness(request): try JSONEncoder().encode(request)
        case let .updateInterests(interests): try JSONEncoder().encode(ProfileInterestsRequest(interests: interests))
        default: nil
        }
    }
}
