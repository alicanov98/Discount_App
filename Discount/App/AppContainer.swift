//
//  AppContainer.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import Observation

@MainActor
@Observable
final class AppContainer {
    let appState: AppState
    let sessionStore: SessionStore
    let homeRepository: any HomeRepositoryProtocol
    let favoritesStore: FavoritesStore

    init() {
        let tokenStore = KeychainService()
        let networkService = DefaultNetworkService(tokenStore: tokenStore)
        let authRepository = AuthRepository(networkService: networkService)
        let sessionStore = SessionStore(
            authRepository: authRepository,
            tokenStore: tokenStore
        )

        self.sessionStore = sessionStore
        appState = AppState(
            tokenStore: tokenStore,
            sessionStore: sessionStore
        )
        let homeRepository = HomeRepository(networkService: networkService)
        self.homeRepository = homeRepository
        favoritesStore = FavoritesStore(
            repository: homeRepository,
             sessionStore: sessionStore
             )
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            sessionStore: sessionStore,
            homeRepository: homeRepository
        )
    }
}
