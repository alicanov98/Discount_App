//
//  AppPreferences.swift
//  Discount
//
//  Created by Malik Alijanov on 09.10.26.
//

import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case azerbaijani = "az"
    case russian = "ru"
    case english = "en"

    var id: String { rawValue }
    var locale: Locale { Locale(identifier: rawValue) }

    var title: String {
        switch self {
        case .azerbaijani: "Azərbaycan dili"
        case .russian: "Русский"
        case .english: "English"
        }
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Sistem"
        case .light: "Açıq"
        case .dark: "Tünd"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}


nonisolated enum AppLocalization {
    static func string(_ key: String) -> String {
        let language = UserDefaults.standard.string(forKey: "app.language") ?? "az"
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return key
        }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }
}
