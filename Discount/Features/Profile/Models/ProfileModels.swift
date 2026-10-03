//
//  ProfileModels.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation

enum ProfileSection: String, Identifiable, Hashable {
    case identity
    case location
    case notifications
    case interests

    var id: String {
        rawValue
    }

    func title(isBusiness: Bool) -> String {
        switch self {
        case .identity:
            isBusiness ? "Biznes məlumatları" : "Şəxsi məlumatlar"
        case .location:
            "Məkan"
        case .notifications:
            "Bildiriş seçimləri"
        case .interests:
            "Maraqlarım"
        }
    }

    var symbol: String {
        switch self {
        case .identity:
            "person.text.rectangle"
        case .location:
            "mappin.and.ellipse"
        case .notifications:
            "bell.badge"
        case .interests:
            "sparkles"
        }
    }

    var subtitle: String {
        switch self {
        case .identity:
            "Ad və əlaqə məlumatlarını idarə et"
        case .location:
            "Saxlanmış məkanını dəyiş"
        case .notifications:
            "Xəbərdarlıqları və yaxınlıq radiusunu seç"
        case .interests:
            "Sənə uyğun kateqoriyaları seç"
        }
    }
}

struct BusinessProfile: Decodable, Equatable {
    let id: Int
    let userID: Int
    let name: String
    let email: String
    let categoryID: Int?
    let phone: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let description: String?
    let logoURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phone
        case address
        case latitude
        case longitude
        case description
        case userID = "user_id"
        case categoryID = "category_id"
        case logoURL = "logo_url"
    }
}

struct ProfileInterestsResponse: Decodable {
    let interests: [String]
}

struct ProfileInterestsRequest: Encodable {
    let interests: [String]
}

struct ProfileUpdateRequest: Encodable {
    var section: ProfileSection? = nil

    let name: String
    let email: String
    let latitude: Double?
    let longitude: Double?
    let notificationRadius: Double
    let notifyNearby: Bool
    let notifyInterests: Bool
    let notifyFavorites: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case email
        case latitude
        case longitude
        case notificationRadius = "notification_radius"
        case notifyNearby = "notify_nearby"
        case notifyInterests = "notify_interests"
        case notifyFavorites = "notify_favorites"
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if section == nil || section == .identity {
            try container.encode(name, forKey: .name)
            try container.encode(email, forKey: .email)
        }

        if section == nil || section == .location {
            try container.encode(latitude, forKey: .latitude)
            try container.encode(longitude, forKey: .longitude)
        }

        if section == nil || section == .notifications {
            try container.encode(notificationRadius, forKey: .notificationRadius)
            try container.encode(notifyNearby, forKey: .notifyNearby)
            try container.encode(notifyInterests, forKey: .notifyInterests)
            try container.encode(notifyFavorites, forKey: .notifyFavorites)
        }
    }
}

struct BusinessUpdateRequest: Encodable {
    var section: ProfileSection? = nil

    let name: String
    let email: String
    let categoryID: Int?
    let phone: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let description: String?
    let logoURL: String?

    enum CodingKeys: String, CodingKey {
        case name
        case email
        case phone
        case address
        case latitude
        case longitude
        case description
        case categoryID = "category_id"
        case logoURL = "logo_url"
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if section == nil || section == .identity {
            try container.encode(name, forKey: .name)
            try container.encode(email, forKey: .email)
            try container.encode(categoryID, forKey: .categoryID)
            try container.encode(phone, forKey: .phone)
            try container.encode(address, forKey: .address)
            try container.encode(description, forKey: .description)
            try container.encode(logoURL, forKey: .logoURL)
        }

        if section == nil || section == .location {
            try container.encode(latitude, forKey: .latitude)
            try container.encode(longitude, forKey: .longitude)
        }
    }
}

struct ProfileDraft: Equatable {
    var name = ""
    var email = ""
    var latitude = ""
    var longitude = ""
    var notificationRadius = "5"
    var notifyNearby = true
    var notifyInterests = true
    var notifyFavorites = true
    var categoryID: Int?
    var phone = ""
    var address = ""
    var description = ""
    var logoURL = ""

    init() {}

    init(user: User) {
        name = user.name
        email = user.email
        latitude = user.latitude.map { String($0) } ?? ""
        longitude = user.longitude.map { String($0) } ?? ""
        notificationRadius = String(user.notificationRadius)
        notifyNearby = user.notifyNearby
        notifyInterests = user.notifyInterests
        notifyFavorites = user.notifyFavorites
    }

    init(business: BusinessProfile) {
        name = business.name
        email = business.email
        latitude = business.latitude.map { String($0) } ?? ""
        longitude = business.longitude.map { String($0) } ?? ""
        categoryID = business.categoryID
        phone = business.phone ?? ""
        address = business.address ?? ""
        description = business.description ?? ""
        logoURL = business.logoURL ?? ""
    }

    func personalRequest(
        section: ProfileSection? = nil
    ) throws -> ProfileUpdateRequest {
        guard section != .interests else {
            throw ProfileValidationError("Maraqları ayrıca saxla.")
        }

        let identity = section == nil || section == .identity
            ? try validatedIdentity()
            : (name: name, email: email)

        let coordinates = section == nil || section == .location
            ? try validatedCoordinates()
            : (latitude: nil as Double?, longitude: nil as Double?)

        var radius = 5.0

        if section == nil || section == .notifications {
            guard let value = Self.number(notificationRadius),
                  value > 0,
                  value <= 500
            else {
                throw ProfileValidationError(
                    "Yaxınlıq radiusu 0-dan böyük və ən çox 500 km olmalıdır."
                )
            }

            radius = value
        }

        return ProfileUpdateRequest(
            section: section,
            name: identity.name,
            email: identity.email,
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            notificationRadius: radius,
            notifyNearby: notifyNearby,
            notifyInterests: notifyInterests,
            notifyFavorites: notifyFavorites
        )
    }

    func businessRequest(
        section: ProfileSection? = nil
    ) throws -> BusinessUpdateRequest {
        guard section == nil || section == .identity || section == .location else {
            throw ProfileValidationError(
                "Bu bölmə biznes hesabı üçün mövcud deyil."
            )
        }

        let identity = section == nil || section == .identity
            ? try validatedIdentity()
            : (name: name, email: email)

        let coordinates = section == nil || section == .location
            ? try validatedCoordinates()
            : (latitude: nil as Double?, longitude: nil as Double?)

        let phone = Self.optionalText(phone)

        if section != .location,
           let phone,
           !(5...30).contains(phone.count)
               || phone.range(
                   of: #"^\\+?[0-9 ()-]+$"#,
                   options: .regularExpression
               ) == nil
        {
            throw ProfileValidationError(
                "Telefon nömrəsini düzgün daxil et: +994 50 000 00 00."
            )
        }

        let logo = Self.optionalText(logoURL)

        if section != .location, let logo {
            guard logo.count <= 2000,
                  let url = URL(string: logo),
                  ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
                  url.host != nil
            else {
                throw ProfileValidationError(
                    "Loqo üçün düzgün http və ya https linki daxil et."
                )
            }
        }

        guard section == .location
            || (address.count <= 500 && description.count <= 5000)
        else {
            throw ProfileValidationError(
                "Ünvan ən çox 500, biznes haqqında məlumat isə 5000 simvol olmalıdır."
            )
        }

        return BusinessUpdateRequest(
            section: section,
            name: identity.name,
            email: identity.email,
            categoryID: categoryID,
            phone: phone,
            address: Self.optionalText(address),
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            description: Self.optionalText(description),
            logoURL: logo
        )
    }

    private func validatedIdentity() throws -> (name: String, email: String) {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !name.isEmpty, name.count <= 120 else {
            throw ProfileValidationError(
                "Ad 1–120 simvol arasında olmalıdır."
            )
        }

        guard email.count <= 254,
              email.range(
                  of: #"^[^\s@]+@[^\s@]+\\.[^\s@]+$"#,
                  options: .regularExpression
              ) != nil
        else {
            throw ProfileValidationError(
                "Düzgün e-poçt ünvanı daxil et."
            )
        }

        return (name, email)
    }

    private func validatedCoordinates() throws -> (
        latitude: Double?,
        longitude: Double?
    ) {
        let latitude = Self.optionalText(latitude)
        let longitude = Self.optionalText(longitude)

        if latitude == nil, longitude == nil {
            return (nil, nil)
        }

        guard let latitude,
              let longitude,
              let lat = Self.number(latitude),
              let lon = Self.number(longitude),
              (-90...90).contains(lat),
              (-180...180).contains(lon)
        else {
            throw ProfileValidationError(
                "Enlik (-90…90) və uzunluğu (-180…180) birlikdə daxil et və ya hər ikisini boş saxla."
            )
        }

        return (lat, lon)
    }

    private static func number(_ text: String) -> Double? {
        guard let number = Double(
            text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: ".")
        ),
            number.isFinite
        else {
            return nil
        }

        return number
    }

    private static func optionalText(_ text: String) -> String? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)

        return value.isEmpty ? nil : value
    }
}

struct ProfileValidationError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}

extension User {
    func updatingIdentity(
        name: String? = nil,
        email: String? = nil,
        interests: [String]? = nil
    ) -> User {
        User(
            id: id,
            name: name ?? self.name,
            email: email ?? self.email,
            role: role,
            interests: interests ?? self.interests,
            latitude: latitude,
            longitude: longitude,
            notifyNearby: notifyNearby,
            notifyInterests: notifyInterests,
            notifyFavorites: notifyFavorites,
            notificationRadius: notificationRadius,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}