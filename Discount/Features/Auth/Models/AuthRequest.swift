//
//  LoginRequest.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RefreshTokenRequest: Encodable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct RegisterRequest: Encodable {
    let name: String
    let email: String
    let password: String
    let role: String
}
