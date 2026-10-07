//
//  HomeLocationService.swift
//  Discount
//
//  Created by Malik Alijanov on 07.10.26.
//

import CoreLocation
import MapKit
import Observation

@MainActor
@Observable
final class HomeLocationService: NSObject, CLLocationManagerDelegate {
    private(set) var title = "Məkan müəyyən edilir…"
    @ObservationIgnored private let manager = CLLocationManager()
    @ObservationIgnored private var geocodingRequest: MKReverseGeocodingRequest?
    @ObservationIgnored private var isActive = false
    @ObservationIgnored private var lastResolvedLocation: CLLocation?
    @ObservationIgnored private var lastAttemptDate: Date?
    @ObservationIgnored private var geocodingTask: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 1000
    }

    func start() {
        guard !isActive else {
            return
        }
        isActive = true
        applyAuthorization()
    }

    func stop() {
        isActive = false
        manager.stopUpdatingLocation()
        if geocodingTask != nil {
            lastAttemptDate = nil
        }
        geocodingTask?.cancel()
        geocodingTask = nil
        geocodingRequest?.cancel()
        geocodingRequest = nil
    }

    private func applyAuthorization() {
        switch manager.authorizationStatus {
        case .notDetermined:
            title = "Məkan icazəsi gözlənilir…"
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            if lastResolvedLocation == nil {
                title = "Məkan müəyyən edilir…"
            }
            manager.startUpdatingLocation()
        case .denied, .restricted:
            stop()
            lastResolvedLocation = nil
            lastAttemptDate = nil
            title = "Məkan icazəsi bağlıdır"
        @unknown default:
            title = "Məkan əlçatan deyil"
        }
    }

    func locationManagerDidChangeAuthorization(_: CLLocationManager) {
        if isActive {
            applyAuthorization()
        }
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isActive, let location = locations.last,
              location.horizontalAccuracy >= 0,
              abs(location.timestamp.timeIntervalSinceNow) < 60
        else {
            return
        }
        guard Self.shouldResolve(
            location, previous: lastResolvedLocation, lastAttemptDate: lastAttemptDate, now: Date()
        ) else {
            return
        }
        guard geocodingTask == nil else {
            return
        }
        lastAttemptDate = Date()
        geocodingTask = Task { [weak self] in
            guard let self else {
                return
            }
            defer {
                if !Task.isCancelled {
                    self.geocodingTask = nil
                    self.geocodingRequest = nil
                }
            }
            do {
                guard let request = MKReverseGeocodingRequest(location: location) else {
                    title = "Məkan müəyyən edilmədi"
                    return
                }
                request.preferredLocale = Locale(identifier: "az_AZ")
                geocodingRequest = request
                let items = try await request.mapItems
                guard isActive, !Task.isCancelled else {
                    return
                }
                let region = items.lazy.compactMap { item in
                    let placemark = item.placemark
                    return HomeHeaderFormatting.regionName(
                        administrativeArea: placemark.administrativeArea,
                        subAdministrativeArea: placemark.subAdministrativeArea,
                        locality: item.addressRepresentations?.cityName ?? placemark.locality,
                        country: item.addressRepresentations?.regionName ?? placemark.country
                    )
                }.first
                guard let region else {
                    title = "Məkan müəyyən edilmədi"
                    return
                }
                lastResolvedLocation = location
                title = region
            } catch {
                guard isActive, !Task.isCancelled else {
                    return
                }
                if lastResolvedLocation == nil {
                    title = "Məkan müəyyən edilmədi"
                }
            }
        }
    }

    func locationManager(_: CLLocationManager, didFailWithError _: Error) {
        guard isActive else {
            return
        }
        if lastResolvedLocation == nil {
            title = "Məkan əlçatan deyil"
        }
    }

    static func shouldResolve(
        _ location: CLLocation, previous: CLLocation?, lastAttemptDate: Date?, now: Date
    ) -> Bool {
        if let previous, location.distance(from: previous) < 1000 {
            return false
        }
        if let lastAttemptDate, now.timeIntervalSince(lastAttemptDate) < 60 {
            return false
        }
        return true
    }
}
