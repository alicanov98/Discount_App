//
//  MapViewModel.swift
//  Discount
//
//  Created by Malik Alijanov on 04.10.26.
//

import CoreLocation
import MapKit
import Observation

@MainActor
@Observable
final class MapViewModel: NSObject, CLLocationManagerDelegate {
    private let repository: any MapRepositoryProtocol
    private let locationManager = CLLocationManager()
    private var requestGeneration = UUID()
    private var searchGeneration = UUID()
    private var activeSearch: MKLocalSearch?
    private var lastLoadedLocation: CLLocation?
    private var isActive = false
    private(set) var location: CLLocation?
    private(set) var selectedArea: CLLocation?
    var searchCenter: CLLocation? { selectedArea ?? location }

    func selectArea(_ area: CLLocation?) {
        selectedArea = area
        requestGeneration = UUID()
        campaigns = []
        errorMessage = nil
        isLoading = false
    }
    private(set) var campaigns: [Campaign] = []
    private(set) var isLoading = false
    private(set) var isSearching = false
    private(set) var searchResults: [MKMapItem] = []
    private(set) var locationMessage: String?
    private(set) var errorMessage: String?
    private(set) var searchError: String?
    private(set) var permissionDenied = false

    init(repository: any MapRepositoryProtocol) {
        self.repository = repository
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 100
    }

    func start() {
        isActive = true
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationMessage = "Yaxınlıqdakı endirimləri görmək üçün məkan icazəsi ver."
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            permissionDenied = false
            locationMessage = location == nil ? "Məkanın müəyyən edilir…" : nil
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            permissionDenied = true
            locationMessage = "Cari məkanını göstərmək üçün Ayarlarda məkan icazəsini aktiv et. Başqa ərazini xəritədən seçə bilərsən."
            location = nil
            lastLoadedLocation = nil
            if selectedArea == nil {
                campaigns = []
                requestGeneration = UUID()
                isLoading = false
            }
        @unknown default: break
        }
    }

    func stop() {
        isActive = false
        locationManager.stopUpdatingLocation()
        lastLoadedLocation = nil
        requestGeneration = UUID()
        searchGeneration = UUID()
        activeSearch?.cancel()
        isLoading = false
        isSearching = false
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Permission callbacks may arrive before the map is visible.
        if isActive && manager.authorizationStatus != .notDetermined { start() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isActive, let latest = locations.last,
              latest.horizontalAccuracy >= 0,
              abs(latest.timestamp.timeIntervalSinceNow) < 60 else { return }
        updateCurrentLocation(latest)
    }

    func updateCurrentLocation(_ latest: CLLocation) {
        location = latest
        locationMessage = nil
        guard selectedArea == nil else { return }
        if lastLoadedLocation.map({ latest.distance(from: $0) >= 100 }) ?? true {
            lastLoadedLocation = latest
            if isActive {
                Task {
                    guard self.isActive, self.selectedArea == nil else { return }
                    await self.loadNearby()
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationMessage = "Məkan alınmadı. GPS və internet bağlantısını yoxla, yenidən cəhd et."
    }

    func loadNearby(at suppliedLocation: CLLocation? = nil) async {
        guard let location = suppliedLocation ?? searchCenter else { start(); return }
        let generation = UUID()
        requestGeneration = generation
        isLoading = true
        errorMessage = nil
        campaigns = []
        defer { if generation == requestGeneration { isLoading = false } }
        var page = 1
        var seen = Set<Int>()
        do {
            while true {
                try Task.checkCancellation()
                let result = try await repository.nearby(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    page: page
                )
                guard generation == requestGeneration, !Task.isCancelled else { return }
                let newItems = result.data.filter { seen.insert($0.id).inserted }
                campaigns.append(contentsOf: newItems.filter {
                    CLLocationCoordinate2DIsValid(.init(latitude: $0.latitude, longitude: $0.longitude))
                    && CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: location) <= 5_000
                })
                if let meta = result.meta {
                    if page >= meta.totalPages { break }
                } else if result.data.count < 100 { break }
                guard !newItems.isEmpty else {
                    errorMessage = "Server bütün nəticələri qaytarmadı. Hazırda alınmış kampaniyalar göstərilir."
                    break
                }
                page += 1
            }
        } catch {
            if generation == requestGeneration, !Task.isCancelled {
                errorMessage = error.localizedDescription
            }
        }
    }

    func search(_ text: String, region: MKCoordinateRegion?) async {
        activeSearch?.cancel()
        let generation = UUID()
        searchGeneration = generation
        searchResults = []
        searchError = nil
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { isSearching = false; return }
        isSearching = true
        defer { if generation == searchGeneration { isSearching = false } }
        do {
            try await Task.sleep(for: .milliseconds(350))
            try Task.checkCancellation()
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = text
            if let region { request.region = region }
            let search = MKLocalSearch(request: request)
            activeSearch = search
            let response = try await search.start()
            guard generation == searchGeneration, !Task.isCancelled else { return }
            searchResults = response.mapItems
            if searchResults.isEmpty { searchError = "Məkan tapılmadı. Başqa ad və ya ünvan yaz." }
        } catch {
            if generation == searchGeneration, !Task.isCancelled {
                searchError = "Axtarış alınmadı. Yenidən cəhd et."
            }
        }
    }
}
