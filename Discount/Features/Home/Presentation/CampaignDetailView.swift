//
//  FavoritesView.swift
//  Discount
//
//  Created by Malik Alijanov on 02.10.26.
//

import MapKit
import SwiftUI

struct CampaignDetailView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.openURL) private var openURL
    @State private var campaign: Campaign
    @State private var isLoading = true
    @State private var errorMessage: String?

    init(campaign: Campaign) {
        _campaign = State(initialValue: campaign)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                CampaignArtwork(campaign: campaign)
                .frame(height: 240).clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(campaign.businessName)
                        .font(AppTypography.caption)
                            .foregroundStyle(Color.appPrimary)
                        Text(campaign.title)
                        .font(AppTypography.title)
                    }
                    Spacer()
                    FavoriteButton(campaign: campaign)
                }
                Text(campaign.discountLabel)
                .font(AppTypography.title)
                    .foregroundStyle(Color.appPrimary)
                if isLoading {
                    AppLoadingView()
                }
                if let errorMessage {
                    CampaignErrorView(message: errorMessage) {
                        Task {
                            await load()
                        }
                    }
                }
                Text("Kampaniya haqqında")
                .font(AppTypography.sectionTitle)
                Text(campaign.description)
                .font(AppTypography.body)
                Label(
                    "\(Campaign.displayDate(campaign.startDate)) – \(Campaign.displayDate(campaign.endDate))",
                    systemImage: "calendar"
                )
                .font(AppTypography.caption)
                Text("İstifadə şərtləri")
                .font(AppTypography.sectionTitle)
                Text(
                    campaign.terms
                        ?? "Əlavə şərt qeyd edilməyib. Ətraflı məlumatı biznesdən əldə edə bilərsən."
                )
                .font(AppTypography.body)
                Text("Burada tapa bilərsən")
                .font(AppTypography.sectionTitle)
                Label(campaign.address, systemImage: "mappin.and.ellipse")
                .font(AppTypography.body)
                Map(
                    initialPosition: .region(
                        MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                        )
                    )
                ) {
                    Marker(campaign.businessName, coordinate: coordinate)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                Button {
                    var url = URLComponents(string: "https://maps.apple.com/")!
                    url.queryItems = [
                        .init(name: "daddr", value: "\(campaign.latitude),\(campaign.longitude)"),
                        .init(name: "dirflg", value: "d")
                    ]
                    if let destination = url.url {
                        openURL(destination)
                    }

                } label: {
                    Label("Yol tarifi al", systemImage: "location.fill")
                        .frame(maxWidth: .infinity).padding(16)
                        .foregroundStyle(Color.appOnPrimary)
                        .background(
                            Color.appPrimary,
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                }
            }
            .padding(20)
        }
        .background(Color.appBackground)
        .navigationTitle("Kampaniya")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private var coordinate: CLLocationCoordinate2D {
        .init(latitude: campaign.latitude, longitude: campaign.longitude)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
        }
        do {
            campaign = try await container.homeRepository.campaign(id: campaign.id)
        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
            }
        }
    }
}
