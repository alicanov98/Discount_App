//
//  Discount_App.swift
//  Discount
//
//  Created by Malik Alijanov on 16.09.26.
//

import SwiftUI

@main
struct Discount_App: App {
    @State private var container = AppContainer()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .environment(container.appState)
                .environment(container.sessionStore)
        }
    }
}
