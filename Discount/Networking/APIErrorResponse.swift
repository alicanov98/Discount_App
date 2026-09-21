//
//  APIErrorResponse.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation

struct APIErrorResponse: Decodable {
    let error: APIErrorDetail
}

struct APIErrorDetail: Decodable {
    let code: String
    let message: String
    let requestID: String?

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case requestID = "request_id"
    }
}
