//
//  AuthRepository.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation

protocol AuthRepositoryProtocol {

    func login(
        email: String,
        password: String
    ) async throws -> LoginResponse
    
    func logout() async throws
    
    func refresh(
           refreshToken: String
       ) async throws -> RefreshTokenResponse
}

final class AuthRepository: AuthRepositoryProtocol {
    private let networkService: any NetworkServiceProtocol
    
    init(networkService: any NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    func login(
        email: String,
        password: String
    ) async throws -> LoginResponse {
        let request = LoginRequest(
            email: email,
            password: password
        )
        
        return try await networkService.request(
            AuthEndpoint.login(request),
            responseType: LoginResponse.self
        )
    }
    
    func refresh(
        refreshToken: String
    ) async throws -> RefreshTokenResponse {
        let request = RefreshTokenRequest(
            refreshToken: refreshToken
        )

        return try await networkService.request(
            AuthEndpoint.refresh(request),
            responseType: RefreshTokenResponse.self
        )
    }
    
    func logout() async throws {
        try await networkService.request(
            AuthEndpoint.logout
        )
    }
    
}
