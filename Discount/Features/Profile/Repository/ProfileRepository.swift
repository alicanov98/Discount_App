//
//  ProfileRepository.swift
//  Discount
//
//  Created by Malik Alijanov on 03.10.26.
//

import Foundation

protocol ProfileRepositoryProtocol {
    func me() async throws -> User
    func business() async throws -> BusinessProfile
    func categories() async throws -> [CampaignCategory]
    func update(_ request: ProfileUpdateRequest) async throws -> User
    func updateBusiness(_ request: BusinessUpdateRequest) async throws -> BusinessProfile
    func updateInterests(_ interests: [String]) async throws -> [String]
    func deleteAccount() async throws
}

final class ProfileRepository: ProfileRepositoryProtocol {
    private let networkService: any NetworkServiceProtocol

    init(networkService: any NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func me() async throws -> User {
        try await networkService.request(
            ProfileEndpoint.me,
            responseType: MeResponseData.self
        ).data
    }

    func business() async throws -> BusinessProfile {
        try await networkService.request(
            ProfileEndpoint.business,
            responseType: HomeDataResponse<BusinessProfile>.self
        ).data
    }

    func categories() async throws -> [CampaignCategory] {
        try await networkService.request(
            HomeEndpoint.categories,
            responseType: HomeDataResponse<[CampaignCategory]>.self
        ).data
    }

    func update(_ request: ProfileUpdateRequest) async throws -> User {
        try await networkService.request(
            ProfileEndpoint.update(request),
            responseType: MeResponseData.self
        ).data
    }

    func updateBusiness(
        _ request: BusinessUpdateRequest
    ) async throws -> BusinessProfile {
        try await networkService.request(
            ProfileEndpoint.updateBusiness(request),
            responseType: HomeDataResponse<BusinessProfile>.self
        ).data
    }

    func updateInterests(
        _ interests: [String]
    ) async throws -> [String] {
        try await networkService.request(
            ProfileEndpoint.updateInterests(interests),
            responseType: HomeDataResponse<ProfileInterestsResponse>.self
        ).data.interests
    }

    func deleteAccount() async throws {
        try await networkService.request(
            ProfileEndpoint.deleteAccount
        )
    }
}