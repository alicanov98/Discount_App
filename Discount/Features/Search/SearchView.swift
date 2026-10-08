//
//  SearchView.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import SwiftUI

struct SearchView: View {
    @Environment(AppContainer.self) private var container
    var initialQuery = CampaignQuery()

    var body: some View {
        CampaignResultsView(repository: container.homeRepository, initialQuery: initialQuery)
    }
}

private struct CampaignResultsView: View {
    @State private var viewModel: CampaignListViewModel
    @State private var query: CampaignQuery
    @State private var searchText: String

    init(repository: any HomeRepositoryProtocol, initialQuery: CampaignQuery) {
        _viewModel = State(initialValue: CampaignListViewModel(repository: repository))
        var query = initialQuery
        query.limit = 20
        _query = State(initialValue: query)
        _searchText = State(initialValue: initialQuery.search)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                filters
                if let error = viewModel.errorMessage {
                    CampaignErrorView(message: error) {
                        Task {
                            await viewModel.load(query)
                        }
                    }
                }
                if viewModel.hasLoaded {
                    Text("\(viewModel.total) təklif")
                    .font(AppTypography.caption)
                        .foregroundStyle(Color.appTextSecondary)
                    if viewModel.campaigns.isEmpty {
                        ContentUnavailableView(
                            "Təklif tapılmadı",
                            systemImage: "magnifyingglass",
                            description: Text("Başqa söz və ya kateqoriya ilə axtar.")
                        )
                    }
                }
                ForEach(viewModel.campaigns) {
                    CampaignCard(campaign: $0)
                }
                if viewModel.isLoading {
                    AppLoadingView()
                }
                if viewModel.canLoadMore {
                    Button("Daha çox göstər") {
                        Task {
                            await viewModel.load(query, more: true)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.isLoading)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
        .navigationTitle("Təklifləri kəşf et")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Kampaniya və ya marka")
        .onSubmit(of: .search) {
            query.search = searchText
        }
        .onChange(of: searchText) {

            _,
            value in
            if value.isEmpty {
                query.search = ""
            }
        }
        .task {
            await viewModel.loadCategories()
        }
        .task(id: query) {
            await viewModel.load(query)
        }
        .refreshable {
            await viewModel.load(query)
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Kateqoriya", selection: $query.categoryID) {
                Text("Bütün kateqoriyalar").tag(nil as Int?)
                if let selectedID = query.categoryID,
                   !viewModel.categories.contains(
                    where: {
                       $0.id == selectedID
                   })
                {
                    Text("Seçilmiş kateqoriya")
                    .tag(Optional(selectedID))
                }
                ForEach(viewModel.categories) {
                    Text($0.displayName)
                    .tag(Optional($0.id))
                }
            }
            Picker("Sıralama", selection: $query.sort) {
                ForEach(CampaignSort.allCases) {
                    Text($0.title).tag($0)
                }
            }
            Toggle(
                "Yalnız PRO təkliflər",
                isOn: Binding(
                    get: {
                        query.isPro == true
                    },
                    set: {
                        query.isPro = $0 ? true : nil
                    }
                )
            )
            if query.radius != nil {
                HStack {
                    Label(
                        "Hesabındakı məkanın 5 km ətrafı", 
                    systemImage: "mappin.and.ellipse"
                    )
                    .font(AppTypography.caption)
                    Spacer()
                    Button("Sıfırla") {
                        query.radius = nil
                    }
                }
            }
        }
        .tint(Color.appPrimary)
        .padding(16)
        .background(
            Color.appCardBackground, 
            in: RoundedRectangle(cornerRadius: 18)
            )
    }
}
