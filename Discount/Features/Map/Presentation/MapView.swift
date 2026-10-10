//
//  MapView.swift
//  Discount
//
//  Created by Malik Alijanov on 04.10.26.
//

import MapKit
import SwiftUI

struct MapView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: MapViewModel
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: .init(latitude: 40.4093, longitude: 49.8671),
            latitudinalMeters: 12_000, longitudinalMeters: 12_000
        )
    )
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var visibleMapRect: MKMapRect?
    @State private var searchText = ""
    @State private var destination: MKMapItem?
    @State private var selectedCampaign: Campaign?
    @State private var detailCampaign: Campaign?
    @State private var pendingDetail: Campaign?
    @State private var showCampaignList = false
    @State private var pendingMapCampaign: Campaign?
    @State private var didCenterOnUser = false
    @State private var isVisible = false
    @FocusState private var searchFocused: Bool

    init(viewModel: MapViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $position, interactionModes: .all) {
                UserAnnotation()
                if let location = viewModel.searchCenter {
                    MapCircle(center: location.coordinate, radius: 5_000)
                        .foregroundStyle(Color.appPrimary.opacity(0.08))
                        .stroke(Color.appPrimary.opacity(0.4), lineWidth: 2)
                }
                ForEach(viewModel.campaigns) { campaign in
                    Annotation(campaign.businessName, coordinate: .init(
                        latitude: campaign.latitude, longitude: campaign.longitude
                    )) {
                        Button {
                            searchFocused = false
                            selectedCampaign = campaign
                        } label: {
                            Text(campaign.discountLabel)
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .foregroundStyle(Color.appOnPrimary)
                                .background(Color.appPrimary, in: Capsule())
                                .overlay(Capsule().stroke(.white, lineWidth: 2))
                                .shadow(radius: 3, y: 2)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(campaign.businessName), \(campaign.discountLabel). Məlumatı aç")
                    }
                }
                if let destination {
                    Marker(destination.name ?? "Seçilən məkan", coordinate: destination.location.coordinate)
                        .tint(.orange)
                }
            }
            .mapStyle(.standard)
            .onMapCameraChange(frequency: .continuous) { context in
                visibleRegion = context.region
                visibleMapRect = context.rect
            }
            .onTapGesture { point in
                guard let coordinate = proxy.convert(point, from: .local) else { return }
                let item = MKMapItem(location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), address: nil)
                item.name = "Seçilən məkan"
                chooseDestination(item)
            }
            .overlay(alignment: .trailing) { zoomControls.padding(.trailing, 16) }
            .safeAreaInset(edge: .top, spacing: 0) { searchPanel }
            .safeAreaInset(edge: .bottom, spacing: 0) { bottomPanel }
        }
        .navigationTitle("Xəritə")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $detailCampaign) { CampaignDetailView(campaign: $0) }
        .sheet(item: $selectedCampaign, onDismiss: {
            if let pendingDetail {
                detailCampaign = pendingDetail
                self.pendingDetail = nil
            }
        }) { campaign in
            campaignSheet(campaign)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCampaignList, onDismiss: {
            if let campaign = pendingMapCampaign {
                center(on: .init(latitude: campaign.latitude, longitude: campaign.longitude), meters: 2_000)
                selectedCampaign = campaign
                pendingMapCampaign = nil
            }
        }) {
            campaignList
        }
        .onAppear { isVisible = true; viewModel.start() }
        .task(id: viewModel.selectedArea) {
            if viewModel.searchCenter != nil { await viewModel.loadNearby() }
        }
        .task(id: searchText) { await viewModel.search(searchText, region: visibleRegion) }
        .onDisappear { isVisible = false; viewModel.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && isVisible {
                viewModel.start()
                if viewModel.selectedArea != nil { Task { await viewModel.loadNearby() } }
            }
            else { viewModel.stop() }
        }
        .onChange(of: viewModel.location) { _, location in
            if let location, !didCenterOnUser, viewModel.selectedArea == nil {
                center(on: location.coordinate, meters: 12_000)
                didCenterOnUser = true
            }
        }
    }

    private var searchPanel: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Məkan və ya ünvan axtar", text: $searchText)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                if viewModel.isSearching { AppLoadingView(placement: .inline) }
                if !searchText.isEmpty {
                    Button { searchText = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .accessibilityLabel("Axtarışı təmizlə")
                }
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            if searchFocused && !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if let error = viewModel.searchError {
                            Text(LocalizedStringKey(error)).font(.callout).padding()
                        }
                        ForEach(Array(viewModel.searchResults.enumerated()), id: \.offset) { _, item in
                            Button { chooseDestination(item) } label: {
                                HStack(alignment: .top) {
                                    Image(systemName: "mappin.circle.fill").foregroundStyle(Color.appPrimary)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.name ?? "Məkan").font(.subheadline.bold())
                                        Text(item.addressRepresentations?.fullAddress(includingRegion: false, singleLine: true) ?? "").font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .foregroundStyle(Color.appTextPrimary)
                                .padding(12)
                            }
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 240)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var bottomPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let destination {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(destination.name ?? "Seçilən məkan").font(.subheadline.bold())
                        Text(destination.addressRepresentations?.fullAddress(includingRegion: false, singleLine: true) ?? "Xəritədə seçdiyin təyinat")
                            .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                    Spacer()
                    Button { returnToMyLocation() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Təyinatı sil")
                }
                Divider()
            }
            HStack {
                if viewModel.isLoading { AppLoadingView(placement: .inline) }
                Label("5 km · \(visibleCampaigns.count) kampaniya", systemImage: "tag.fill")
                    .font(.subheadline.bold())
                Spacer()
                Button {
                    Task { await viewModel.loadNearby() }
                } label: { Image(systemName: "arrow.clockwise") }
                    .accessibilityLabel("Bu ərazidəki kampaniyaları yenilə")
                Button { returnToMyLocation() } label: { Image(systemName: "location.fill") }
                    .accessibilityLabel("Məkanımı göstər və kampaniyaları yenilə")
            }
            Text(LocalizedStringKey(destination == nil ? "Olduğun məkanın ətrafında" : "Seçdiyin məkanın ətrafında"))
                .font(.caption).foregroundStyle(.secondary)
            Button { showCampaignList = true; searchFocused = false } label: {
                Label("Kampaniyalara siyahıda bax", systemImage: "list.bullet")
                    .font(AppTypography.button)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.searchCenter == nil)
            Text("Məkan seçmək üçün xəritəyə toxun.")
                .font(.caption).foregroundStyle(.secondary)
            if let message = viewModel.locationMessage, viewModel.selectedArea == nil {
                Text(LocalizedStringKey(message)).font(.caption)
                if viewModel.permissionDenied {
                    Button("Ayarları aç") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                    .font(.subheadline.bold())
                } else {
                    Button("Məkanı yenidən yoxla") { viewModel.start() }.font(.caption)
                }
            } else if let error = viewModel.errorMessage {
                Text(LocalizedStringKey(error)).font(.caption).foregroundStyle(Color.appDanger)
                Button("Yenidən cəhd et") { Task { await viewModel.loadNearby() } }.font(.caption)
            } else if !viewModel.isLoading && viewModel.searchCenter != nil && viewModel.campaigns.isEmpty {
                Text("5 km ətrafında kampaniya tapılmadı.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .padding(16)
    }

    private func campaignSheet(_ campaign: Campaign) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(campaign.businessName).font(AppTypography.sectionTitle)
                    Spacer()
                    Button { selectedCampaign = nil } label: { Image(systemName: "xmark.circle.fill") }
                        .accessibilityLabel("Bağla")
                }
                CampaignArtwork(campaign: campaign)
                    .frame(height: 140).clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                Text(campaign.title).font(AppTypography.title)
                Text(campaign.discountLabel).font(AppTypography.sectionTitle).foregroundStyle(Color.appPrimary)
                Text(campaign.description).font(AppTypography.body).lineLimit(3)
                Label(campaign.address, systemImage: "mappin.and.ellipse").font(AppTypography.caption)
                Label("\(Campaign.displayDate(campaign.endDate)) tarixinədək", systemImage: "calendar")
                    .font(AppTypography.caption)
                Button {
                    pendingDetail = campaign
                    selectedCampaign = nil
                } label: {
                    Text("Kampaniyanın detallarına bax")
                        .font(AppTypography.button)
                        .frame(maxWidth: .infinity).padding(14)
                        .foregroundStyle(Color.appOnPrimary)
                        .background(Color.appPrimary, in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
        }
        .background(Color.appBackground)
    }

    private func chooseDestination(_ item: MKMapItem) {
        destination = item
        searchFocused = false
        searchText = ""
        selectedCampaign = nil
        viewModel.selectArea(item.location)
        center(on: item.location.coordinate, meters: 12_000)
    }

    private func returnToMyLocation() {
        destination = nil
        selectedCampaign = nil
        if let location = viewModel.location { center(on: location.coordinate, meters: 12_000) }
        if viewModel.selectedArea != nil {
            viewModel.selectArea(nil)
        } else {
            Task { await viewModel.loadNearby() }
        }
        viewModel.start()
    }

    private var visibleCampaigns: [Campaign] {
        guard let visibleMapRect else { return [] }
        return viewModel.campaigns.filter { campaign in
            visibleMapRect.contains(MKMapPoint(CLLocationCoordinate2D(
                latitude: campaign.latitude, longitude: campaign.longitude
            )))
        }
    }

    private var campaignList: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    Text(destination?.name.map { "\($0) · 5 km ətrafında" } ?? "Cari məkanın · 5 km ətrafında")
                        .font(AppTypography.sectionTitle)
                    Text("Xəritədə görünən \(visibleCampaigns.count) kampaniya")
                        .font(AppTypography.caption).foregroundStyle(.secondary)
                    if viewModel.isLoading { AppLoadingView() }
                    if let error = viewModel.errorMessage {
                        CampaignErrorView(message: error) { Task { await viewModel.loadNearby() } }
                    }
                    if !viewModel.isLoading && viewModel.errorMessage == nil && visibleCampaigns.isEmpty {
                        ContentUnavailableView("Kampaniya tapılmadı", systemImage: "tag", description: Text("Xəritənin görünən hissəsində kampaniya yoxdur. Başqa kampaniyaları görmək üçün xəritəni sürüşdür və ya uzaqlaşdır."))
                    }
                    ForEach(visibleCampaigns) { campaign in
                        VStack(alignment: .leading, spacing: 8) {
                            CampaignCard(campaign: campaign)
                            Button {
                                pendingMapCampaign = campaign
                                showCampaignList = false
                            } label: {
                                Label("Xəritədə göstər", systemImage: "mappin.and.ellipse")
                                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle("Ərazidəki kampaniyalar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Bağla") { showCampaignList = false }
                }
            }
        }
    }

    private var zoomControls: some View {
        VStack(spacing: 0) {
            Button { zoom(by: 0.5) } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .frame(width: 48, height: 48)
            }
            .accessibilityLabel("Xəritəni yaxınlaşdır")
            Divider().frame(width: 32)
            Button { zoom(by: 2) } label: {
                Image(systemName: "minus")
                    .font(.title3.weight(.semibold))
                    .frame(width: 48, height: 48)
            }
            .accessibilityLabel("Xəritəni uzaqlaşdır")
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.appPrimary)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }

    private func zoom(by factor: Double) {
        guard var region = visibleRegion ?? position.region else { return }
        region.span.latitudeDelta = min(max(region.span.latitudeDelta * factor, 0.001), 160)
        region.span.longitudeDelta = min(max(region.span.longitudeDelta * factor, 0.001), 360)
        visibleRegion = region
        withAnimation { position = .region(region) }
    }

    private func center(on coordinate: CLLocationCoordinate2D, meters: Double) {
        let region = MKCoordinateRegion(
            center: coordinate, latitudinalMeters: meters, longitudinalMeters: meters
        )
        visibleRegion = region
        withAnimation { position = .region(region) }
    }
}
