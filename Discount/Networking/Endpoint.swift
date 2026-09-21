//
//  Endpoint.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation

protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem] { get }
    var headers: [String: String] { get }
    var requiresAuthorization: Bool { get }

    func body() throws -> Data?
}


extension Endpoint {

    var queryItems: [URLQueryItem] {
        []
    }

    var headers: [String: String] {
        [:]
    }

    var requiresAuthorization: Bool {
        true
    }

    func body() throws -> Data? {
        nil
    }
}
