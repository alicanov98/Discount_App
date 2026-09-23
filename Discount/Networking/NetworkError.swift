//
//  NetworkError.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case refreshTokenNotFound

    case unauthorized(
        code: String?,
        message: String?,
        requestID: String?
    )

    case serverError(
        statusCode: Int,
        code: String?,
        message: String?,
        requestID: String?
    )

    case decodingError(Error)
    case encodingError(Error)
    case noInternet
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL düzgün deyil."

        case .invalidResponse:
            return "Serverdən düzgün cavab alınmadı."
        case .refreshTokenNotFound:
            return "Refresh token tapilmadi"
        case .unauthorized(let code, let message, _):
            if code == "INVALID_CREDENTIALS" {
                return "E-poçt və ya şifrə yanlışdır."
            }

            return message ?? "Avtorizasiya xətası baş verdi."

        case .serverError(let statusCode, _, let message, _):
            return "Server xətası: \(statusCode) - \(message ?? "Xəta baş verdi")"

        case .decodingError(let error):
            return """
            Response oxunarkən xəta baş verdi:
            \(error.localizedDescription)
            """

        case .encodingError(let error):
            return """
            Məlumat hazırlanarkən xəta baş verdi:
            \(error.localizedDescription)
            """

        case .noInternet:
            return "İnternet bağlantısı yoxdur."

        case .unknown(let error):
            return error.localizedDescription
        }
    }
}
