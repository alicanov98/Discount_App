//
//  AccountType.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation

enum AccountType: String, CaseIterable, Identifiable {
    case user = "İstifadəçi"
    case business = "Biznes"
    var id: Self { self }
}
