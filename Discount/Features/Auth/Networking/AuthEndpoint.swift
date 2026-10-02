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
    case register(RegisterRequest)
    case forgetPassword(ForgetPasswordRequest)
    case resetPassword(ResetPasswordRequest)
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
        case .register:
            return "auth/register"
        case .forgetPassword:
            return "auth/forgot-password"
        case .resetPassword:
            return "/auth/reset-password"
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
        case .register:
            return .post
        case .forgetPassword:
            return .post
        case .resetPassword:
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
        case .register:
            return false
        case .forgetPassword:
            return false
        case .resetPassword:
            return false
        }
    }

    func body() throws -> Data? {
        switch self {
        case let .login(request):
            do {
                return try JSONEncoder().encode(request)
            } catch {
                throw NetworkError.encodingError(error)
            }
        case .logout:
            return nil
        case let .refresh(request):
            do {
                return try JSONEncoder().encode(request)
            } catch {
                throw NetworkError.encodingError(error)
            }
        case let .register(request):
            do {
                return try JSONEncoder().encode(request)
            } catch {
                throw NetworkError.encodingError(error)
            }
        case let .forgetPassword(request):
            do {
                return try JSONEncoder().encode(request)
            } catch {
                throw NetworkError.encodingError(error)
            }
        case let .resetPassword(request):
            do {
                return try JSONEncoder().encode(request)
            } catch {
                throw NetworkError.encodingError(error)
            }
        }
    }
}
