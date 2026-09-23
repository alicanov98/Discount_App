import Observation

@MainActor
@Observable
final class AppContainer {
    let appState: AppState
    let sessionStore: SessionStore
    private let homeRepository: any HomeRepositoryProtocol

    init() {
        let tokenStore = KeychainService()
        let networkService = DefaultNetworkService(tokenStore: tokenStore)
        let authRepository = AuthRepository(networkService: networkService)
        let sessionStore = SessionStore(
            authRepository: authRepository,
            tokenStore: tokenStore
        )

        self.sessionStore = sessionStore
        self.appState = AppState(
            tokenStore: tokenStore,
            sessionStore: sessionStore
        )
        self.homeRepository = HomeRepository(networkService: networkService)
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            sessionStore: sessionStore,
            homeRepository: homeRepository
        )
    }
}
