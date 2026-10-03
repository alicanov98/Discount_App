//
//  ProfileTests.swift
//  Discount
//
//  Created by Malik Alijanov on 03.10.26.
//

@testable import Discount
import Foundation
import Testing

@MainActor
struct ProfileTests {
    @Test
    func separateEditorsEncodeOnlyTheirOwnFields() throws {
        var draft = ProfileDraft(user: User.mock)
        draft.latitude = ""
        draft.longitude = ""

        var request = try draft.personalRequest()
        request.section = .identity

        var json = try #require(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(request)
            ) as? [String: Any]
        )

        #expect(Set(json.keys) == ["name", "email"])

        request.section = .location
        json = try #require(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(request)
            ) as? [String: Any]
        )

        #expect(Set(json.keys) == ["latitude", "longitude"])
        #expect(json["latitude"] is NSNull)

        request.section = .notifications
        json = try #require(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(request)
            ) as? [String: Any]
        )

        #expect(
            Set(json.keys) == [
                "notification_radius",
                "notify_nearby",
                "notify_interests",
                "notify_favorites"
            ]
        )

        var business = try ProfileDraft(
            business: profileBusinessFixture
        ).businessRequest()

        business.section = .location
        json = try #require(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(business)
            ) as? [String: Any]
        )

        #expect(Set(json.keys) == ["latitude", "longitude"])

        business.section = .identity
        json = try #require(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(business)
            ) as? [String: Any]
        )

        #expect(json["latitude"] == nil)
        #expect(json["longitude"] == nil)
        #expect(json["name"] != nil)
    }

    @Test
    func editingOneSectionDoesNotValidateUnrelatedFields() throws {
        var draft = ProfileDraft(user: User.mock)
        draft.latitude = "invalid"
        draft.notificationRadius = "invalid"

        #expect(
            try draft.personalRequest(section: .identity).name == User.mock.name
        )

        draft.name = ""
        draft.latitude = "40.4"

        #expect(
            try draft.personalRequest(section: .location).latitude == 40.4
        )

        var business = ProfileDraft(business: profileBusinessFixture)
        business.phone = "invalid"
        business.logoURL = "invalid"

        #expect(
            try business.businessRequest(section: .location).latitude == 40.4
        )
    }

    @Test
    func editorKeepsUncommittedDraftLocalAndCommitsOnlyAfterSuccess() async {
        let fixture = makeProfileFixture()
        await fixture.model.load()

        let original = fixture.model.draft
        var edited = original
        edited.name = "Ayrıca səhifədə dəyişən ad"

        fixture.repository.failWrites = true

        #expect(
            await fixture.model.saveProfile(
                section: .identity,
                editedDraft: edited
            ) == false
        )
        #expect(fixture.model.draft == original)
        #expect(fixture.session.currentUser?.name == original.name)

        fixture.repository.failWrites = false

        #expect(
            await fixture.model.saveProfile(
                section: .identity,
                editedDraft: edited
            )
        )
        #expect(fixture.repository.personalRequest?.section == .identity)
        #expect(fixture.session.currentUser?.name == edited.name)
        #expect(fixture.model.draft.name == edited.name)
    }

    @Test
    func clearedLocationAndBusinessFieldsEncodeAsNull() throws {
        var personal = ProfileDraft(user: User.mock)
        personal.latitude = ""
        personal.longitude = ""
        personal.notificationRadius = "0,5"

        let request = try personal.personalRequest()
        let json = try #require(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(request)
            ) as? [String: Any]
        )

        #expect(json["latitude"] is NSNull)
        #expect(json["longitude"] is NSNull)
        #expect(json["notification_radius"] as? Double == 0.5)

        var business = ProfileDraft(business: profileBusinessFixture)
        business.phone = ""
        business.address = ""
        business.categoryID = nil
        business.logoURL = ""

        let businessJSON = try #require(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(business.businessRequest())
            ) as? [String: Any]
        )

        #expect(businessJSON["phone"] is NSNull)
        #expect(businessJSON["address"] is NSNull)
        #expect(businessJSON["category_id"] is NSNull)
        #expect(businessJSON["logo_url"] is NSNull)
        #expect(businessJSON["notify_nearby"] == nil)
    }

    @Test
    func rejectsUnpairedCoordinatesAndInvalidRadius() throws {
        var draft = ProfileDraft(user: User.mock)
        draft.longitude = ""

        #expect(throws: ProfileValidationError.self) {
            try draft.personalRequest()
        }

        draft.latitude = ""
        draft.notificationRadius = "0"

        #expect(throws: ProfileValidationError.self) {
            try draft.personalRequest()
        }

        draft.notificationRadius = "501"

        #expect(throws: ProfileValidationError.self) {
            try draft.personalRequest()
        }

        draft.notificationRadius = "nan"

        #expect(throws: ProfileValidationError.self) {
            try draft.personalRequest()
        }

        draft.notificationRadius = "500"

        #expect(try draft.personalRequest().notificationRadius == 500)
    }

    @Test
    func userDecodesFractionalNotificationRadius() throws {
        var json = try #require(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(User.mock)
            ) as? [String: Any]
        )

        json["notification_radius"] = 0.5

        let decoded = try JSONDecoder().decode(
            User.self,
            from: JSONSerialization.data(withJSONObject: json)
        )

        #expect(decoded.notificationRadius == 0.5)
    }

    @Test
    func failedSavePreservesEditsAndSession() async {
        let fixture = makeProfileFixture()
        await fixture.model.load()

        fixture.model.draft.name = "Yeni ad"
        fixture.repository.failWrites = true

        await fixture.model.saveProfile()

        #expect(fixture.model.draft.name == "Yeni ad")
        #expect(fixture.model.hasProfileChanges)
        #expect(fixture.session.currentUser?.name == User.mock.name)
        #expect(fixture.model.successMessage == nil)
        #expect(fixture.model.isShowingError)
        #expect(!fixture.model.isBusy)
    }

    @Test
    func personalSaveUsesServerResponseWithoutDiscardingUnsavedInterests() async {
        let fixture = makeProfileFixture()
        await fixture.model.load()

        fixture.model.selectedInterests = ["beauty"]
        fixture.model.draft.name = "  Yeni ad  "

        await fixture.model.saveProfile()

        #expect(fixture.repository.personalRequest?.name == "Yeni ad")
        #expect(fixture.session.currentUser?.name == "Yeni ad")
        #expect(!fixture.model.hasProfileChanges)
        #expect(fixture.model.hasInterestChanges)
        #expect(fixture.model.selectedInterests == ["beauty"])
        #expect(fixture.model.successMessage != nil)
        #expect(fixture.repository.businessRequest == nil)
    }

    @Test
    func interestsUseSlugsAndUpdateSharedUser() async {
        let fixture = makeProfileFixture()
        await fixture.model.load()

        fixture.model.selectedInterests = ["beauty", "fashion"]
        fixture.model.draft.name = "Saxlanılmayan ad"

        await fixture.model.saveInterests()

        #expect(fixture.repository.submittedInterests == ["beauty", "fashion"])
        #expect(fixture.session.currentUser?.interests == ["beauty", "fashion"])
        #expect(!fixture.model.hasInterestChanges)
        #expect(fixture.model.draft.name == "Saxlanılmayan ad")
        #expect(fixture.model.hasProfileChanges)
    }

    @Test
    func businessSaveUsesBusinessEndpointAndUpdatesIdentity() async {
        let fixture = makeProfileFixture(user: User.mockBusiness)
        await fixture.model.load()

        #expect(fixture.model.isBusiness)

        fixture.model.draft.name = "Yeni biznes"
        fixture.model.draft.phone = "+994 50 123 45 67"

        await fixture.model.saveProfile()

        #expect(fixture.repository.businessRequest?.name == "Yeni biznes")
        #expect(fixture.repository.personalRequest == nil)
        #expect(fixture.session.currentUser?.name == "Yeni biznes")
        #expect(fixture.model.business?.phone == "+994 50 123 45 67")
        #expect(!fixture.model.hasProfileChanges)
    }

    @Test
    func accountDeletionClearsTokensOnlyAfterServerSuccess() async {
        let fixture = makeProfileFixture()
        await fixture.model.load()

        fixture.repository.failWrites = true

        await fixture.model.deleteAccount()

        #expect(fixture.session.isAuthenticated)
        #expect(fixture.tokens.accessToken != nil)
        #expect(fixture.appState.flow == .main)

        fixture.repository.failWrites = false

        await fixture.model.deleteAccount()

        #expect(!fixture.session.isAuthenticated)
        #expect(fixture.session.currentUser == nil)
        #expect(fixture.tokens.accessToken == nil)
        #expect(fixture.tokens.refreshToken == nil)
        #expect(fixture.appState.flow == .authentication)
    }

    private func makeProfileFixture(
        user: User = .mock
    ) -> (
        model: ProfileViewModel,
        repository: FakeProfileRepository,
        session: SessionStore,
        tokens: ProfileMemoryTokens,
        appState: AppState
    ) {
        let tokens = ProfileMemoryTokens()
        let session = SessionStore(
            authRepository: AuthRepository(
                networkService: ProfileUnusedNetworkService()
            ),
            tokenStore: tokens
        )

        session.currentUser = user

        let appState = AppState(
            tokenStore: tokens,
            sessionStore: session
        )

        appState.flow = .main

        let repository = FakeProfileRepository(user: user)

        return (
            ProfileViewModel(
                repository: repository,
                sessionStore: session,
                appState: appState
            ),
            repository,
            session,
            tokens,
            appState
        )
    }
}

private let profileBusinessFixture = BusinessProfile(
    id: 2,
    userID: 2,
    name: "Coffee House",
    email: "business@example.com",
    categoryID: 3,
    phone: "+994500000000",
    address: "Bakı",
    latitude: 40.4,
    longitude: 49.8,
    description: "Qəhvə məkanı",
    logoURL: nil
)

@MainActor
private final class FakeProfileRepository: ProfileRepositoryProtocol {
    var user: User
    var failWrites = false
    var personalRequest: ProfileUpdateRequest?
    var businessRequest: BusinessUpdateRequest?
    var submittedInterests: [String]?

    init(user: User) {
        self.user = user
    }

    func me() async throws -> User {
        user
    }

    func business() async throws -> BusinessProfile {
        profileBusinessFixture
    }

    func categories() async throws -> [CampaignCategory] {
        [
            .init(id: 1, slug: "fashion", name: "Fashion"),
            .init(id: 4, slug: "beauty", name: "Beauty")
        ]
    }

    func update(_ request: ProfileUpdateRequest) async throws -> User {
        if failWrites {
            throw URLError(.notConnectedToInternet)
        }

        personalRequest = request
        user = user.updatingIdentity(
            name: request.name,
            email: request.email
        )

        return user
    }

    func updateBusiness(
        _ request: BusinessUpdateRequest
    ) async throws -> BusinessProfile {
        if failWrites {
            throw URLError(.notConnectedToInternet)
        }

        businessRequest = request

        return BusinessProfile(
            id: 2,
            userID: 2,
            name: request.name,
            email: request.email,
            categoryID: request.categoryID,
            phone: request.phone,
            address: request.address,
            latitude: request.latitude,
            longitude: request.longitude,
            description: request.description,
            logoURL: request.logoURL
        )
    }

    func updateInterests(
        _ interests: [String]
    ) async throws -> [String] {
        if failWrites {
            throw URLError(.notConnectedToInternet)
        }

        submittedInterests = interests

        return interests
    }

    func deleteAccount() async throws {
        if failWrites {
            throw URLError(.notConnectedToInternet)
        }
    }
}

private final class ProfileMemoryTokens: TokenStore {
    var accessToken: String? = "test-access"
    var refreshToken: String? = "test-refresh"

    func saveTokens(
        accessToken: String,
        refreshToken: String
    ) throws {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func clearTokens() throws {
        accessToken = nil
        refreshToken = nil
    }
}

private struct ProfileUnusedNetworkService: NetworkServiceProtocol {
    func request<Response: Decodable>(
        _: any Endpoint,
        responseType _: Response.Type
    ) async throws -> Response {
        throw URLError(.unsupportedURL)
    }

    func request(_: any Endpoint) async throws {
        throw URLError(.unsupportedURL)
    }
}