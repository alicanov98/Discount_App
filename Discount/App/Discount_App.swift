//
//  Discount_App.swift
//  Discount
//
//  Created by Malik Alijanov on 16.09.26.
//

import SwiftUI

#if DEBUG
    import Pulse
    import PulseProxy
#endif

@main
struct Discount_App: App {
    @AppStorage("app.language") private var language: AppLanguage = .azerbaijani
    @AppStorage("app.appearance") private var appearance: AppAppearance = .system
    @State private var container = AppContainer()

    init() {
        #if DEBUG
            NetworkLogger.enableProxy()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.locale, language.locale)
                .preferredColorScheme(appearance.colorScheme)
                .environment(container)
                .environment(container.appState)
                .environment(container.sessionStore)
        }
    }
}
