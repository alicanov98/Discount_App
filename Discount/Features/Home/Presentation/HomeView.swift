//
//  HomeView.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var searchText = ""
    @State private var searchQuery: CampaignQuery?

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                hero
                searchBar
                categories
                if let error = viewModel.errorMessage {
                    CampaignErrorView(message: error) {
                        Task {
                            await viewModel.load()
                        }
                    }
                }
                if viewModel.isLoading {
                    ProgressView("Fürsətlər yüklənir…")
                    .frame(maxWidth: .infinity)
                }
                ForEach(viewModel.sections) {
                    section in
                    campaignSection(section)
                }
            }
            .padding(20)
        }
        .background(Color.appBackground)
        .navigationTitle("kəşf.")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $searchQuery) {
            query in SearchView(initialQuery: query)
        }
        .toolbar {
            #if DEBUG
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        NetworkingDebugView()

                    } label: {
                        Image(systemName: "network")
                    }
                }
            #endif
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ŞƏHƏRDƏ YENİ NƏ VAR?")
            .font(AppTypography.caption)
            .foregroundStyle(Color.appPrimary)
            Text(
                "Salam, \(viewModel.user?.name.components(separatedBy: " ").first ?? "xoş gəldin")"
            )
            .font(AppTypography.title)
            .foregroundStyle(Color.appTextPrimary)
            Text("Gününə dəyər qatan təklifləri kəşf et.")
                .font(AppTypography.body)
                .foregroundStyle(Color.appTextSecondary)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("AZ XƏRCLƏ. ÇOX YAŞA.", systemImage: "sparkles")
            .font(AppTypography.caption)
            Text("Şəhər dolusu fürsət.\nSənin üçün seçildi.").font(AppTypography.title)
            Text("Sevdiyin markalar və qaçırmaq istəməyəcəyin endirimlər bir yerdə.")
                .font(AppTypography.body)
            Button {
                searchQuery = CampaignQuery()
            } label: {
                Label("Təklifləri kəşf et", systemImage: "arrow.up.right")
                    .font(AppTypography.button).padding(14)
                    .foregroundStyle(Color.appPrimary)
                    .background(Color.appWhite, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .foregroundStyle(Color.appOnPrimary)
        .background(
            LinearGradient(
                colors: [Color.appPrimary, Color.appViolet],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26)
        )
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
            .foregroundStyle(Color.appTextMuted)
            TextField("Kampaniya, marka, məkan…", text: $searchText)
                .submitLabel(.search)
                .onSubmit {
                    searchQuery = CampaignQuery(search: searchText)
                }
            Button {
                searchQuery = CampaignQuery(search: searchText)
            } label: {
                Image(systemName: "arrow.right")
                .frame(width: 44, height: 44)
                    .foregroundStyle(Color.appOnPrimary)
                    .background(
                        Color.appPrimary,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
            }
            .accessibilityLabel("Axtar")
        }
        .padding(10).background(
            Color.appCardBackground, 
        in: RoundedRectangle(cornerRadius: 18)
        )
        .overlay(RoundedRectangle(cornerRadius: 18)
        .stroke(Color.appBorder))
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
                            SearchView(initialQuery: CampaignQuery(categoryID: category.id))

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

    private func campaignSection(_ section: HomeCampaignSection) -> some View {
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
            if let error = section.error {
                CampaignErrorView(message: error) {
                    Task {
                        await viewModel.load()
                    }
                }

            } else if section.campaigns.isEmpty && !viewModel.isLoading {
                Text("Yeni fürsətlər yoldadır. Uyğun kampaniyalar burada görünəcək.")
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appTextSecondary)
                    .padding(
                        .vertical,
                        12
                    )

            } else {
                ForEach(section.campaigns) {
                    CampaignCard(campaign: $0)
                }
            }
        }
    }
}
