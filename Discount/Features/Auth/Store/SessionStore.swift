//
//  SessionStore.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation
import Observation

@MainActor
@Observable
final class SessionStore {
    
    private(set) var currentUser: User?
    private(set) var isAuthenticated: Bool
    
    private let authRepository: any AuthRepositoryProtocol
    private let tokenStore: any TokenStore
    
    init(
        authRepository: any AuthRepositoryProtocol,
        tokenStore: any TokenStore
    ) {
        self.authRepository = authRepository
        self.tokenStore = tokenStore
        self.isAuthenticated = tokenStore.accessToken != nil
    }
}

extension SessionStore {
    func login(
        email: String,
        password: String
    ) async throws {
        let response = try await authRepository.login(email: email, password: password)
        
        try tokenStore.saveTokens(
            accessToken: response.data.accessToken,
            refreshToken: response.data.refreshToken
        )
        
        currentUser =  response.data.user
        isAuthenticated = true
    }
    
    func logout() async throws {
        do{
            try await authRepository.logout()
            try tokenStore.clearTokens()
            currentUser = nil
            isAuthenticated = false

        }catch{
            #if DEBUG
            print("Server error",error.localizedDescription)
            #endif
            throw error
        }
       
    }
}



