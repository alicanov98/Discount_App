//
//  AuthRepository.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation

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
    
    func logout() async throws {
        try await networkService.request(
            AuthEndpoint.logout
        )
    }
    
}
