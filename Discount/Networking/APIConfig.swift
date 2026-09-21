//
//  APIConfig.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation

enum APIConfig {

    static var baseURL: URL? {
     #if DEBUG
        URL(string: "http://localhost:5174/api")
     #else
        URL(string: "production api")
     #endif
    }
}
