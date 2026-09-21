//
//  AppState.swift
//  Discount
//
//  Created by Malik Alijanov on 16.09.26.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class AppState {
    var flow: AppFlow
    private let tokenStore: any TokenStore
    
    init(tokenStore: any TokenStore) {
        self.tokenStore = tokenStore
        
        
        let hasSeenOnboarding =
        UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
        
        let hasValidSession = tokenStore.accessToken != nil
        
        if !hasSeenOnboarding {
            flow = .onboarding
        } else if hasValidSession {
            flow = .main
        }else {
            flow = .authentication
        }
    
    }
    
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        flow = .authentication
    }
    
    func loginCompleted() {
        flow = .main
    }
    
    func logoutCompleted() {
        flow = .authentication
    }
}
