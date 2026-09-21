//
//  LoginResponse.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

struct LoginResponse: Decodable {
    let data: ResponseData
    
    struct ResponseData: Decodable {
        let user: User
        let accessToken: String
        let refreshToken: String
        let tokenType: String
        let expiresIn: Int
        let refreshExpiresAt: String
        
        enum CodingKeys: String, CodingKey {
            case user
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case tokenType = "token_type"
            case expiresIn = "expires_in"
            case refreshExpiresAt = "refresh_expires_at"
        }
    }

}

