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
    case refresh(RefreshTokenRequest)
}

extension AuthEndpoint: Endpoint {
    var path: String {
        switch self {
        case .login:
            return "auth/login"
        case .logout:
            return "auth/logout"
        case .refresh:
            return "auth/refresh"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login:
            return .post
        case .logout:
            return .post
        case .refresh:
            return .post
        }
    }
    
    var requiresAuthorization: Bool {
        switch self {
        case .login:
            return false
        case .logout:
            return true
        case .refresh:
            return false
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
        case .refresh(let request):
            do {
                return try JSONEncoder().encode(request)
            }catch {
                throw NetworkError.encodingError(error)
            }
        }
    }
}
