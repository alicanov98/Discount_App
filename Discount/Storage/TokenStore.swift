//
//  TokenStore.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

protocol TokenStore: AnyObject {
    var accessToken: String? { get }
    var refreshToken: String? { get }

    func saveTokens(
        accessToken: String,
        refreshToken: String
    ) throws

    func clearTokens() throws
}
