//
//  ImageURLBuilder.swift
//  Discount
//
//  Created by Malik Alijanov on 05.10.26.
//

import Foundation

nonisolated enum ImageSource: Equatable, Sendable {
    case remote(URL)
    case embedded(Data)
}

nonisolated enum ImageURLBuilder {
    static func makeSource(path: String?) -> ImageSource? {
        guard let path = path?.trimmingCharacters(in: .whitespacesAndNewlines),
              !path.isEmpty else { return nil }
        if path.prefix(5).lowercased() == "data:" {
            guard let separator = path.firstIndex(of: ",") else { return nil }
            let header = path[..<separator].lowercased()
            guard header.hasPrefix("data:image/"), header.hasSuffix(";base64"),
                  let data = Data(base64Encoded: String(path[path.index(after: separator)...])),
                  !data.isEmpty else { return nil }
            return .embedded(data)
        }
        return makeURL(path: path).map(ImageSource.remote)
    }

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
