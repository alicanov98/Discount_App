//
//  DefaultNetworkService.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation

@MainActor
final class DefaultNetworkService: NetworkServiceProtocol {

    private let session: URLSession
    private let tokenStore: any TokenStore
    private let decoder: JSONDecoder
    private var refreshTask: Task<Void, Error>?
    var onSessionExpired: (() -> Void)?

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
        responseType _: Response.Type
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
        let accessToken = tokenStore.accessToken
        do {
            return try await sendRequest(endpoint)
        } catch NetworkError.unauthorized where endpoint.requiresAuthorization {
            if tokenStore.accessToken == accessToken {
                try await refreshAccessToken()
            }
            try Task.checkCancellation()
            return try await sendRequest(endpoint)
        }
    }

    func refreshAccessToken() async throws {
        if let refreshTask {
            try await refreshTask.value
            return
        }
        guard let refreshToken = tokenStore.refreshToken, !refreshToken.isEmpty else {
            try? tokenStore.clearTokens()
            onSessionExpired?()
            throw NetworkError.refreshTokenNotFound
        }
        let accessToken = tokenStore.accessToken
        let task = Task { @MainActor in
            do {
                let data = try await self.sendRequest(
                    AuthEndpoint.refresh(RefreshTokenRequest(refreshToken: refreshToken))
                )
                let response = try self.decoder.decode(RefreshTokenResponse.self, from: data)
                guard self.tokenStore.refreshToken == refreshToken,
                      self.tokenStore.accessToken == accessToken else {
                    throw CancellationError()
                }
                try self.tokenStore.saveTokens(
                    accessToken: response.data.accessToken,
                    refreshToken: response.data.refreshToken
                )
            } catch {
                if self.tokenStore.refreshToken == refreshToken,
                   self.tokenStore.accessToken == accessToken {
                    switch error {
                    case NetworkError.unauthorized,
                         NetworkError.serverError(statusCode: 403, code: _, message: _, requestID: _):
                        try? self.tokenStore.clearTokens()
                        self.onSessionExpired?()
                    default:
                        break 
                    }
                }
                throw error
            }
        }
        refreshTask = task
        defer { refreshTask = nil }
        try await task.value
    }

    func sendRequest(
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

        for (key, value) in endpoint.headers {
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
