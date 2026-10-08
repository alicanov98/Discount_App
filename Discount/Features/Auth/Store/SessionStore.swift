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
    var currentUser: User?
    private(set) var isAuthenticated: Bool

    private let authRepository: any AuthRepositoryProtocol
    let tokenStore: any TokenStore

    init(
        authRepository: any AuthRepositoryProtocol,
        tokenStore: any TokenStore
    ) {
        self.authRepository = authRepository
        self.tokenStore = tokenStore
        isAuthenticated = tokenStore.accessToken != nil
    }
}

extension SessionStore {
    func clearSession() throws {
        currentUser = nil
        isAuthenticated = false
        try tokenStore.clearTokens()
    }

    func login(
        email: String,
        password: String
    ) async throws {
        let response = try await authRepository.login(email: email, password: password)

        try tokenStore.saveTokens(
            accessToken: response.data.accessToken,
            refreshToken: response.data.refreshToken
        )

        currentUser = response.data.user
        isAuthenticated = true
    }

    func register(
        name: String,
        email: String,
        password: String,
        role: String
    ) async throws {
        let response = try await authRepository.register(name: name, email: email, password: password, role: role)
        try tokenStore.saveTokens(accessToken: response.data.accessToken, refreshToken: response.data.refreshToken)
        currentUser = response.data.user
        isAuthenticated = true
    }

    func forgetPassword(email: String) async throws -> ForgetPasswordResponse {
        return try await authRepository.forgetPassword(email: email)
    }

    func resetPassword(token: String, password: String) async throws -> ResetPasswordResponse {
        return try await
            authRepository.resetPassword(token: token, password: password)
    }

    func refresh() async throws {
        guard let refreshToken = tokenStore.refreshToken, !refreshToken.isEmpty else {
            throw NetworkError.refreshTokenNotFound
        }
        do {
            let response: RefreshTokenResponse = try await authRepository.refresh(refreshToken: refreshToken)
            try tokenStore.saveTokens(accessToken: response.data.accessToken, refreshToken: response.data.refreshToken)

            isAuthenticated = true
        } catch {
            #if DEBUG
                print("Server error", error.localizedDescription)
            #endif
            switch error {
            case NetworkError.unauthorized,
                 NetworkError.serverError(statusCode: 403, code: _, message: _, requestID: _):
                try? clearSession()
            default:
                break
            }
            throw error
        }
    }

    func logout() async throws {
        do {
            try await authRepository.logout()
            try tokenStore.clearTokens()
            currentUser = nil
            isAuthenticated = false

        } catch {
            #if DEBUG
                print("Server error", error.localizedDescription)
            #endif
            throw error
        }
    }
}
