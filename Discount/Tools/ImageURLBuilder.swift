//
//  ImageURLBuilder.swift
//  Discount
//
//  Created by Malik Alijanov on 05.10.26.
//

import Foundation

enum ImageURLBuilder {
    static func makeURL(path: String?) -> URL? {
        guard let path = path?.trimmingCharacters(in: .whitespacesAndNewlines),
              !path.isEmpty,
              let url = URL(string: path, relativeTo: APIConfig.baseURL)?.absoluteURL,
              let scheme = url.scheme?.lowercased(),
              ["https", "http"].contains(scheme),
              let host = url.host, !host.isEmpty
        else {
            return nil
        }

        return url
    }
}
