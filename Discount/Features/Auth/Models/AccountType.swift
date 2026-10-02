//
//  AccountType.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation

enum AccountType: String, CaseIterable, Identifiable {
    case user
    case business

    var id: Self {
        self
    }

    var selectedType: String {
        switch self {
        case .user: "Şəxsi"
        case .business: "Biznes"
        }
    }
}

enum AccountTypeError: LocalizedError {
    case unsupportedValue(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedValue:
            return "Hesab növü dəstəklənmir."
        }
    }
}
