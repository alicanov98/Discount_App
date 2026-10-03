//
//  MainTabView.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import SwiftUI

struct MainTabView: View {
    
    @Environment(AppContainer.self) private var container

    var body: some View {
        TabView {
            NavigationStack {
                HomeView(viewModel: container.makeHomeViewModel())
            }
            .tabItem {
                Label("Ana səhifə", systemImage: "house")
            }
            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Axtar", systemImage: "magnifyingglass")
            }
            NavigationStack {
                FavoritesView()
            }
            .tabItem {
                Label("Seçilmişlər", systemImage: "heart")
            }
            NavigationStack {
                ProfileView(viewModel: container.makeProfileViewModel())
            }
            .tabItem {
                Label("Profil", systemImage: "person")
            }
        }
        .tint(Color.appPrimary)
        .environment(container.favoritesStore)
        .task(id: container.sessionStore.currentUser?.id) {
            await container.favoritesStore.load()
        }
        .alert(
            "Seçilmişlər yenilənmədi",
            isPresented: Binding(
                get: {
                    container.favoritesStore.errorMessage != nil
                },
                set: {
                    if !$0 {
                        container.favoritesStore.errorMessage = nil
                    }
                }
            )
        ) {
            Button("Yenidən cəhd et") {
                Task {
                    await container.favoritesStore.load()
                }
            }
            Button("Bağla", role: .cancel) {
                container.favoritesStore.errorMessage = nil
            }

        } message: {
            Text(container.favoritesStore.errorMessage ?? "")
        }
    }
}
