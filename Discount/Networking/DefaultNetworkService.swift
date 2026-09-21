//
//  DefaultNetworkService.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation

final class DefaultNetworkService: NetworkServiceProtocol {

    private let session: URLSession
    private let tokenStore: any TokenStore
    private let decoder: JSONDecoder

    init(
        session: URLSession = .shared,
        tokenStore: any TokenStore,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.tokenStore = tokenStore
        self.decoder = decoder
    }

    func request<Response: Decodable>(
        _ endpoint: any Endpoint,
        responseType: Response.Type
    ) async throws -> Response {
        let data = try await performRequest(endpoint)

        do {
            return try decoder.decode(
                Response.self,
                from: data
            )
        } catch {
            printDecodingError(
                error,
                data: data
            )

            throw NetworkError.decodingError(error)
        }
    }

    func request(
        _ endpoint: any Endpoint
    ) async throws {
        _ = try await performRequest(endpoint)
    }
}

private extension DefaultNetworkService {

    func performRequest(
        _ endpoint: any Endpoint
    ) async throws -> Data {
        let request = try makeRequest(for: endpoint)

        do {
            let (data, response) = try await session.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            try validateResponse(
                httpResponse,
                data: data
            )

            return data
        } catch let error as NetworkError {
            throw error
        } catch let error as URLError
            where error.code == .notConnectedToInternet {
            throw NetworkError.noInternet
        } catch {
            throw NetworkError.unknown(error)
        }
    }


    func makeRequest(
        for endpoint: any Endpoint
    ) throws -> URLRequest {
        guard let baseURL = APIConfig.baseURL else {
            throw NetworkError.invalidURL
        }

        let url = baseURL.appendingPathComponent(
            endpoint.path
        )

        guard var components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ) else {
            throw NetworkError.invalidURL
        }

        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }

        guard let finalURL = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: finalURL)

        request.httpMethod = endpoint.method.rawValue
        request.httpBody = try endpoint.body()
        request.timeoutInterval = 30

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        if request.httpBody != nil {
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
        }

        endpoint.headers.forEach { key, value in
            request.setValue(
                value,
                forHTTPHeaderField: key
            )
        }

        if endpoint.requiresAuthorization {
            guard let token = tokenStore.accessToken else {
                throw NetworkError.unauthorized(
                    code: nil,
                    message: "Access token tapılmadı.",
                    requestID: nil
                )
            }

            request.setValue(
                "Bearer \(token)",
                forHTTPHeaderField: "Authorization"
            )
        }

        return request
    }


    func validateResponse(
        _ response: HTTPURLResponse,
        data: Data
    ) throws {
        guard !(200...299).contains(response.statusCode) else {
            return
        }

        let apiError = try? decoder.decode(
            APIErrorResponse.self,
            from: data
        )

        switch response.statusCode {
        case 401:
            throw NetworkError.unauthorized(
                code: apiError?.error.code,
                message: apiError?.error.message,
                requestID: apiError?.error.requestID
            )

        default:
            throw NetworkError.serverError(
                statusCode: response.statusCode,
                code: apiError?.error.code,
                message: apiError?.error.message,
                requestID: apiError?.error.requestID
            )
        }
    }




    func printDecodingError(
        _ error: Error,
        data: Data
    ) {
#if DEBUG
        print("Decoding error:", error)

        if let json = String(
            data: data,
            encoding: .utf8
        ) {
            print("Response JSON:", json)
        }
#endif
    }
}
