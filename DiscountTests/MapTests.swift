//
//  MapTests.swift
//  Discount
//
//  Created by Malik Alijanov on 04.10.26.
//

@testable import Discount
import CoreLocation
import Foundation
import Testing

@MainActor
struct MapTests {
    @Test
    func nearbyLoadsEveryPageAndFiltersOutsideRadius() async throws {
        let repository = MapTestRepository()
        repository.pages = [
            [
                makeCampaign(id: 1),
                makeCampaign(id: 2, latitude: 41.4)
            ],
            [
                makeCampaign(id: 1),
                makeCampaign(id: 3)
            ]
        ]

        let model = MapViewModel(repository: repository)

        await model.loadNearby(
            at: CLLocation(latitude: 40.4093, longitude: 49.8671)
        )

        #expect(repository.requestedPages == [1, 2])
        #expect(model.campaigns.map(\.id) == [1, 3])
        #expect(model.errorMessage == nil)
        #expect(!model.isLoading)
    }

    @Test
    func oldLocationResponseCannotReplaceNewLocation() async {
        let repository = MapTestRepository()
        repository.pages = [[makeCampaign(id: 2)]]
        repository.suspendFirstRequest = true

        let model = MapViewModel(repository: repository)

        let old = Task {
            await model.loadNearby(
                at: CLLocation(latitude: 40, longitude: 49)
            )
        }

        while repository.continuation == nil {
            await Task.yield()
        }

        await model.loadNearby(
            at: CLLocation(latitude: 40.4093, longitude: 49.8671)
        )

        repository.continuation?.resume(
            returning: .init(
                data: [makeCampaign(id: 1)],
                meta: nil
            )
        )

        await old.value

        #expect(model.campaigns.map(\.id) == [2])
    }

    @Test
    func repeatingServerPageStopsWithPartialResultsMessage() async {
        let repository = MapTestRepository()
        repository.pages = [
            [makeCampaign(id: 1)],
            [makeCampaign(id: 1)],
            [makeCampaign(id: 3)]
        ]

        let model = MapViewModel(repository: repository)

        await model.loadNearby(
            at: CLLocation(latitude: 40.4093, longitude: 49.8671)
        )

        #expect(repository.requestedPages == [1, 2])
        #expect(model.campaigns.count == 1)
        #expect(model.errorMessage != nil)
    }

    @Test
    func selectedAreaUsesDestinationCoordinatesAndIgnoresGPSMovement() async {
        let repository = MapTestRepository()
        repository.pages = [
            [
                makeCampaign(id: 1),
                makeCampaign(id: 2, latitude: 41.4)
            ]
        ]

        let model = MapViewModel(repository: repository)

        model.updateCurrentLocation(
            CLLocation(latitude: 40.4093, longitude: 49.8671)
        )

        await model.loadNearby()

        #expect(model.campaigns.map(\.id) == [1])

        model.selectArea(
            CLLocation(latitude: 41.4, longitude: 49.8671)
        )

        #expect(model.campaigns.isEmpty)

        await model.loadNearby()

        #expect(repository.coordinates.last?.latitude == 41.4)
        #expect(model.campaigns.map(\.id) == [2])

        model.updateCurrentLocation(
            CLLocation(latitude: 40.5, longitude: 49.8)
        )

        await model.loadNearby()

        #expect(repository.coordinates.last?.latitude == 41.4)
        #expect(model.searchCenter?.coordinate.latitude == 41.4)
        #expect(model.location?.coordinate.latitude == 40.5)

        model.updateCurrentLocation(
            CLLocation(latitude: 40.4093, longitude: 49.8671)
        )
        model.selectArea(nil)

        await model.loadNearby()

        #expect(repository.coordinates.last?.latitude == 40.4093)
        #expect(model.campaigns.map(\.id) == [1])
    }

    @Test
    func selectedAreaWorksWithoutLocationPermission() async {
        let repository = MapTestRepository()
        repository.pages = [[makeCampaign(id: 1)]]

        let model = MapViewModel(repository: repository)

        model.selectArea(
            CLLocation(latitude: 40.4093, longitude: 49.8671)
        )

        await model.loadNearby()

        #expect(model.location == nil)
        #expect(model.campaigns.map(\.id) == [1])
    }

    @Test
    func changingAreaInvalidatesPreviousResponseImmediately() async {
        let repository = MapTestRepository()
        repository.suspendFirstRequest = true

        let model = MapViewModel(repository: repository)

        let old = Task {
            await model.loadNearby(
                at: CLLocation(latitude: 40.4093, longitude: 49.8671)
            )
        }

        while repository.continuation == nil {
            await Task.yield()
        }

        model.selectArea(
            CLLocation(latitude: 41.4, longitude: 49.8671)
        )

        repository.continuation?.resume(
            returning: .init(
                data: [makeCampaign(id: 1)],
                meta: nil
            )
        )

        await old.value

        #expect(model.campaigns.isEmpty)
        #expect(model.searchCenter?.coordinate.latitude == 41.4)
    }

    @Test
    func nearbyResponseDecodesProvidedContract() throws {
        let data = Data(
            """
            {"data": [], "meta": {"page":1,"limit":100,"total":0,"total_pages":0}}
            """.utf8
        )

        let response = try JSONDecoder().decode(
            NearbyCampaignResponse.self,
            from: data
        )

        #expect(response.data.isEmpty)
        #expect(response.meta?.limit == 100)
    }
}

@MainActor
private final class MapTestRepository: MapRepositoryProtocol {
    var pages: [[Campaign]] = []
    var requestedPages: [Int] = []
    var coordinates: [CLLocationCoordinate2D] = []
    var suspendFirstRequest = false
    var continuation: CheckedContinuation<NearbyCampaignResponse, Never>?

    func nearby(
        latitude: Double,
        longitude: Double,
        page: Int
    ) async throws -> NearbyCampaignResponse {
        requestedPages.append(page)
        coordinates.append(
            .init(latitude: latitude, longitude: longitude)
        )

        if suspendFirstRequest {
            suspendFirstRequest = false

            return await withCheckedContinuation {
                continuation = $0
            }
        }

        return .init(
            data: pages[page - 1],
            meta: .init(
                page: page,
                limit: 100,
                total: pages.reduce(0) { $0 + $1.count },
                totalPages: pages.count
            )
        )
    }
}

private func makeCampaign(
    id: Int,
    latitude: Double = 40.4093
) -> Campaign {
    Campaign(
        id: id,
        businessID: 1,
        businessName: "Biznes",
        title: "Endirim",
        description: "Təklif",
        imageURL: nil,
        terms: nil,
        categoryID: 1,
        discountType: "percentage",
        discountValue: 25,
        startDate: "2026-10-03",
        endDate: "2026-10-31",
        latitude: latitude,
        longitude: 49.8671,
        address: "Bakı",
        status: "active",
        isPro: false,
        isBoosted: false,
        distance: nil
    )
}