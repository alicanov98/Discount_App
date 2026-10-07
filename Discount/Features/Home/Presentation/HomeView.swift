//
//  HomeView.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            if viewModel.showsInitialLoading {
                ProgressView("Fürsətlər yüklənir…")
                    .frame(maxWidth: .infinity)
                    .padding(20)
            } else {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    heroCarousel
                    categories
                    if let error = viewModel.errorMessage {
                        CampaignErrorView(message: error) {
                            Task {
                                await viewModel.load()
                            }
                        }
                    }
                    ForEach(viewModel.visibleSections) { section in
                        HomeCampaignSectionView(section: section)
                    }
                }
                .padding(20)
            }
        }
        .background(Color.appBackground)
        .task {
            await viewModel.loadIfNeeded()
        }
        .task(id: scenePhase) {
            if scenePhase == .active {
                await viewModel.monitorHeader()
            }
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(viewModel.greeting)
                        .font(AppTypography.body)
                        .foregroundStyle(Color.appTextSecondary)
                    Text("Fürsətləri kəşf et")
                        .font(AppTypography.largeTitle)
                        .foregroundStyle(Color.appTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                #if DEBUG

                    NavigationLink {
                        NetworkingDebugView()

                    } label: {
                        Image(systemName: "network")
                    }

                #endif
                Image(systemName: "bell")
                    .font(.system(size: 25, weight: .regular))
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(width: 48, height: 48)
                    .background(
                        Color.appCardBackground,
                        in: RoundedRectangle(cornerRadius: 17)
                    )
                    .overlay(alignment: .topTrailing) {
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: 8, height: 8)
                            .overlay { Circle().stroke(Color.appCardBackground, lineWidth: 2) }
                            .offset(x: -3, y: 3)
                    }
                    .shadow(color: Color.appShadow.opacity(0.08), radius: 14, y: 5)
                    .accessibilityHidden(true)
            }

            Text("Gününə dəyər qatan təkliflər.")
                .font(AppTypography.body)
                .foregroundStyle(Color.appTextSecondary)

            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                Text(viewModel.locationTitle)
                    .font(AppTypography.font(size: 18, weight: .semiBold))
            }
            .foregroundStyle(Color.appPrimary)
            .accessibilityElement(children: .combine)
        }
        .padding(.top, 8)
    }

    private var categories: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bir maraqdan başla")
                .font(AppTypography.sectionTitle)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(viewModel.categories) {
                        category in
                        NavigationLink {
                            SearchView(initialQuery: viewModel.query(for: category))

                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: category.symbol).font(.title2)
                                    .frame(width: 64, height: 60)
                                    .background(
                                        Color.appPrimarySoft,
                                        in: RoundedRectangle(cornerRadius: 18)
                                    )
                                Text(category.displayName)
                                    .font(AppTypography.caption)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 84)
                            .foregroundStyle(Color.appTextPrimary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var heroCarousel: some View {
        CarouselView(
            cards: viewModel.heroCampaigns,
            spacing: 12,
            scalesWithPosition: true,
            autoPlayInterval: 4
        ) { campaign in
            NavigationLink {
                CampaignDetailView(campaign: campaign)
            } label: {
                HeroSectionCard(campaign: campaign)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(campaign.title), \(campaign.discountLabel)")
        }
    }
}

private struct HomeCampaignSectionView: View {
    let section: HomeCampaignSection

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(section.title)
                        .font(AppTypography.sectionTitle)
                    Text(section.subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(Color.appTextSecondary)
                }
                Spacer()
                NavigationLink {
                    SearchView(initialQuery: section.query)
                } label: {
                    Text("Hamısı")
                        .font(AppTypography.caption)
                        .foregroundStyle(Color.appPrimary)
                }
            }
            ForEach(section.campaigns) {
                CampaignCard(campaign: $0)
            }
        }
    }
}

#Preview {
    let container = AppContainer()

    NavigationStack {
        HomeView(
            viewModel: HomeViewModel(
                sessionStore: container.sessionStore,
                homeRepository: container.homeRepository
            )
        )
    }
    .environment(container)
    .environment(container.appState)
    .environment(container.favoritesStore)
}
