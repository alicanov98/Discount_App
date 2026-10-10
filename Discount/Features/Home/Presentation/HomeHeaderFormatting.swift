//
//  HomeHeaderFormatting.swift
//  Discount
//
//  Created by Malik Alijanov on 07.10.26.
//

import Foundation

nonisolated enum HomeHeaderFormatting {
    static func greeting(name: String?, date: Date, calendar: Calendar = .autoupdatingCurrent) -> String {
        let salutation: String
        switch calendar.component(.hour, from: date) {
        case 5 ..< 12:
            salutation = AppLocalization.string("Sabahın xeyir")
        case 12 ..< 17:
            salutation = AppLocalization.string("Günortan xeyir")
        case 17 ..< 22:
            salutation = AppLocalization.string("Axşamın xeyir")
        default:
            salutation = AppLocalization.string("Gecən xeyrə")
        }
        guard let firstName = name?.split(whereSeparator: { $0.isWhitespace }).first else {
            return "\(salutation) 👋"
        }
        return "\(salutation), \(firstName) 👋"
    }

    static func regionName(
        administrativeArea: String?, subAdministrativeArea: String?, locality: String?, country: String? = nil
    ) -> String? {
        var countryNames: Set = [
            "azerbaycan", "azerbaijan", "azerbaycan respublikasi", "republic of azerbaijan",
        ]
        if let country {
            countryNames.insert(normalizedName(country))
        }
        let areas = [administrativeArea, subAdministrativeArea, locality].compactMap { value -> String? in
            guard let value else {
                return nil
            }
            let name = cleanedName(value)
            guard !name.isEmpty, !countryNames.contains(normalizedName(name)) else {
                return nil
            }
            return name
        }
        for area in areas {
            switch normalizedName(area) {
            case "baku", "baki":
                return "Bakı"
            case "absheron", "abseron":
                return "Abşeron"
            case "shamakhi", "samaxi":
                return "Şamaxı"
            default:
                continue
            }
        }

        for candidate in [subAdministrativeArea, locality, administrativeArea].compactMap({ $0 }) {
            let name = cleanedName(candidate)
            if areas.contains(name) {
                return name
            }
        }
        return nil
    }

    private static func cleanedName(_ value: String) -> String {
        var name = value.trimmingCharacters(in: .whitespacesAndNewlines)
        for suffix in [" rayonu", " şəhəri", " district", " city", " rayon"] {
            if name.lowercased().hasSuffix(suffix) {
                name = String(name.dropLast(suffix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return name
    }

    private static func normalizedName(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en"))
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: "ə", with: "e")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
