//
//  Discount_App.swift
//  Discount
//
//  Created by Malik Alijanov on 16.09.26.
//

import SwiftUI

@main
struct Discount_App: App {
    @State private var appState: AppState
    @State private var sessionStore: SessionStore
    
    init(){
        let tokenStore = KeychainService()
        
        let networkService = DefaultNetworkService(
            tokenStore: tokenStore
        )
        
        let authRepository = AuthRepository(
            networkService: networkService
        )
        
       let sessionStore = SessionStore(
        authRepository: authRepository,
        tokenStore: tokenStore
       )
        
        _appState = State(
            initialValue: AppState(
              tokenStore: tokenStore
            ))
        
        _sessionStore = State(
          initialValue: sessionStore
          )
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(sessionStore)
        }
    }
}
