//
//  MainTabView.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
        HomeView()
          .tabItem {
                Label("Ana səhifə", systemImage: "house")
           }
        SearchView()
                .tabItem {
                    Label("Axtar", systemImage: "magnifyingglass")
                }
        FavoritesView()
                .tabItem {
                    Label("Secilmisler", systemImage: "heart")
                }
        ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person")
                }
        }
    }
}

#Preview {
    MainTabView()
}
