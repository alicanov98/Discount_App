//
//  NetworkServiceProtocol.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

protocol NetworkServiceProtocol {
    func request<Response: Decodable>(
        _ endpoint: any Endpoint,
        responseType: Response.Type
    ) async throws -> Response

    func request(
        _ endpoint: any Endpoint
    ) async throws
}
