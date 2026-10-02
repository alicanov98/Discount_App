//
//  FavoritesView.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import SwiftUI

struct FavoritesView: View {
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !favorites.canSave {
                    ContentUnavailableView(
                        "Seçilmişlər",
                        systemImage: "heart",
                        description: Text("Seçilmişlərə əlavə etmək şəxsi hesablar üçün mövcuddur.")
                    )

                } else {
                    if let error = favorites.errorMessage {
                        CampaignErrorView(message: error) {
                            Task {
                                await favorites.load()
                            }
                        }
                    }
                    if favorites.isLoading {
                        ProgressView("Seçilmişlər yüklənir…")

                    } else if favorites.hasLoaded && favorites.campaigns.isEmpty {
                        ContentUnavailableView(
                            "Hələ seçilmiş təklif yoxdur",
                            systemImage: "heart",
                            description: Text("Bəyəndiyin kampaniyalardakı ürək düyməsinə toxun.")
                        )
                    }
                    ForEach(favorites.campaigns) {
                        CampaignCard(campaign: $0)
                    }
                }
            }
            .padding(20)
        }
        .background(Color.appBackground)
        .navigationTitle("Seçilmişlər")
        .task {
            await favorites.load()
        }
        .refreshable {
            await favorites.load()
        }
    }
}
