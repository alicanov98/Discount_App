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
    
    func register(name:String,
                  email:String,
                  password:String,
                  role:String) async throws -> RegisterResponse
    
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
    
    func register(
        name:String,
        email:String,
        password:String,
        role:String
    ) async throws -> RegisterResponse {
        let request = RegisterRequest(name: name, email: email, password: password, role: role)
        
        return try await networkService.request(AuthEndpoint.register(request), responseType: RegisterResponse.self)
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
