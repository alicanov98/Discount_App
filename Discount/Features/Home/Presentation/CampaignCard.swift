//
//  CampaignArtwork.swift
//  Discount
//
//  Created by Malik Alijanov on 02.10.26.
//

import SwiftUI
import SDWebImageSwiftUI

struct CampaignArtwork: View {
    let campaign: Campaign

    var body: some View {
        GeometryReader {
            geometry in
            AppImage(source: campaign.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .empty:
                    Color.appPrimarySoft.overlay { ProgressView() }
                case .failure:
                    fallback
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
                )
            .clipped()
        }
        .contentShape(Rectangle())
        .accessibilityHidden(true)
    }

    private var fallback: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appPrimarySoft, Color.appLavender],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "tag")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(Color.appPrimary)
        }
    }
}

struct FavoriteButton: View {
    let campaign: Campaign
    @Environment(FavoritesStore.self) private var favorites

    var body: some View {
        if favorites.canSave {
            Button {
                Task {
                    await favorites.toggle(campaign)
                }

            } label: {
                Image(systemName: favorites.contains(campaign.id) ? "heart.fill" : "heart")
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: 44, height: 44)
                    .background(
                        Color.appCardBackground, in: Circle()
                        )
            }
            .buttonStyle(.plain)
            .disabled(
                !favorites.hasLoaded || favorites.isLoading
                    || favorites.pendingIDs
                    .contains(campaign.id)
            )
            .accessibilityLabel(
                favorites.contains(campaign.id) ? "Seçilmişlərdən çıxar" : "Seçilmişlərə əlavə et"
            )
        }
    }
}

struct CampaignCard: View {
    let campaign: Campaign

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                NavigationLink {
                    CampaignDetailView(campaign: campaign)

                } label: {
                    CampaignArtwork(campaign: campaign)
                        .frame(height: 170).clipped()
                        .contentShape(Rectangle())
                        .overlay(alignment: .bottomLeading) {
                            Text(campaign.discountLabel)
                                .font(AppTypography.button)
                                .padding(10)
                                .foregroundStyle(Color.appOnPrimary)
                                .background(Color.appPrimary, in: Capsule())
                                .padding(12)
                        }
                        .overlay(alignment: .topLeading) {
                            if campaign.isPro {
                                Label("PRO", systemImage: "sparkles")
                                    .font(.caption.bold()).padding(8)
                                    .background(Color.appCardBackground, in: Capsule())
                                    .padding(12)
                            }
                        }
                }
                FavoriteButton(campaign: campaign).padding(10)
            }
            NavigationLink {
                CampaignDetailView(campaign: campaign)

            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(campaign.businessName)
                    .font(AppTypography.caption)
                    .foregroundStyle(Color.appPrimary)
                    Text(campaign.title)
                    .font(AppTypography.sectionTitle)
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(2)
                    Label(
                        campaign.distance
                            .map {
                                "\($0.formatted(.number.precision(.fractionLength(1)))) km"
                            } ?? campaign.address,
                        systemImage: "mappin.and.ellipse"
                    )
                    .font(AppTypography.caption)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(1)
                    Text("\(Campaign.displayDate(campaign.endDate))-dək")
                        .font(AppTypography.caption)
                        .foregroundStyle(Color.appTextMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
        }
        .buttonStyle(.plain)
        .background(
            Color.appCardBackground, 
            in: RoundedRectangle(cornerRadius: 22)
            )
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22)
        .stroke(Color.appBorder, lineWidth: 1))
    }
}

struct CampaignErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Label(message, systemImage: "exclamationmark.triangle")
            .font(AppTypography.body)
            Button("Yenidən cəhd et", action: retry)
            .buttonStyle(.bordered)
        }
        .foregroundStyle(Color.appTextSecondary)
        .frame(maxWidth: .infinity)
        .padding()
    }
}
