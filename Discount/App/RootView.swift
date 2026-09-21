//
//  RootView.swift
//  Discount
//
//  Created by Malik Alijanov on 16.09.26.
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self)
       private var appState

       @Environment(SessionStore.self)
       private var sessionStore
    
    var body: some View {
        Group {
            switch appState.flow {
            case .onboarding:
                OnboardingView {
                    appState.completeOnboarding()
                }
            case .authentication:
                LoginView(
                   sessionStore: sessionStore
                  )
            case .main:
                MainTabView()
            
          }
        }
        .animation(.easeInOut, value: appState.flow)
    }
}

#Preview {
    RootView()
}
