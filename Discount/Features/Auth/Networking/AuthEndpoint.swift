//
//  AuthEndpoint.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation

enum AuthEndpoint {
    case login(LoginRequest)
    case logout
}

extension AuthEndpoint: Endpoint {
    var path: String {
        switch self {
        case .login:
            return "auth/login"
        case .logout:
            return "auth/logout"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login:
            return .post
        case .logout:
            return .post
        }
    }
    
    var requiresAuthorization: Bool {
        switch self {
        case .login:
            return false
        case .logout:
            return true
        }
    }
    
    func body() throws -> Data? {
        switch self {
        case .login(let request):
            do {
                return try JSONEncoder().encode(request)
            }catch {
                throw NetworkError.encodingError(error)
            }
        case .logout:
            return nil
        }
    }
}
