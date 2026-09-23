//
//  HomeEndpoint.swift
//  Discount
//
//  Created by Malik Alijanov on 21.09.26.
//

import Foundation

enum HomeEndpoint {
    case me
}

extension HomeEndpoint: Endpoint {
    var path: String {
        switch self {
        case .me:
            return "users/me"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .me:
            return .get
        }
    }
    
    func body() throws -> Data? {
        switch self {
        case .me:
            return nil
        }
    }
}


