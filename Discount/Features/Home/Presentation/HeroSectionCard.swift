//
//  HeroSectionCard.swift
//  Discount
//
//  Created by Malik Alijanov on 06.10.26.
//

import SwiftUI
import SDWebImageSwiftUI

struct HeroSectionCard: View {
    let campaign: Campaign
    private let imageHeight: CGFloat = 250
    var body: some View {
        Color.appPrimarySoft
            .frame(height: imageHeight)
            .overlay {
                AppImage(source: campaign.imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .empty:
                        Color.appPrimarySoft.overlay { AppLoadingView(placement: .inline) }
                    case .failure:
                        fallback
                    }
                }
            }
            .clipped()
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.65)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: imageHeight * 0.35)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .bottomLeading) {
                Text(campaign.title)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(16)
            }
            .overlay(alignment: .topTrailing) {
                if campaign.isPro {
                    Image(systemName:"crown.fill")
                            .foregroundStyle(Color.appWarning)
                            .font(AppTypography.sectionTitle)
                            .padding(16)
                    }
        }

            .clipShape(RoundedRectangle(cornerRadius: 20))
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

#Preview {
    HeroSectionCard(campaign: Campaign.mock)
}
