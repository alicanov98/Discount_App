//
//  APIConfig.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation

enum APIConfig {

    nonisolated static var baseURL: URL? {
     #if DEBUG
        URL(string: "https://discoundback.alicanov.dev")
     #else
        URL(string: "https://discoundback.alicanov.dev")
     #endif
    }
}
