//
//  AppImage.swift
//  Discount
//
//  Created by Malik Alijanov on 07.10.26.
//

import CryptoKit
import SDWebImage
import SDWebImageSwiftUI
import SwiftUI

struct AppImage<Content: View>: View {
    let source: String?
    private let content: (WebImagePhase) -> Content
    @State private var resolvedSource: ResolvedImageSource = .empty

    init(source: String?, @ViewBuilder content: @escaping (WebImagePhase) -> Content) {
        self.source = source
        self.content = content
    }

    var body: some View {
        Group {
            switch resolvedSource {
            case .empty:
                content(.empty)
            case let .remote(url):
                WebImage(url: url, content: content)
                    .stableLoading()
                    .id(url)
            case let .embedded(image):
                content(.success(Image(uiImage: image)))
            case .failure:
                content(.failure(ImageSourceError.invalidImage))
            }
        }
        .task(id: source) {
            resolvedSource = .empty
            let result = await ImageSourceResolver.shared.resolve(source)
            guard !Task.isCancelled else { return }
            resolvedSource = result
        }
    }
}

nonisolated enum ResolvedImageSource: Sendable {
    case empty
    case remote(URL)
    case embedded(UIImage)
    case failure
}

private enum ImageSourceError: Error {
    case invalidImage
}

actor ImageSourceResolver {
    static let shared = ImageSourceResolver()
    private let cache = NSCache<NSString, UIImage>()

    init() {
        cache.totalCostLimit = 64 * 1024 * 1024
        cache.countLimit = 100
    }

    func resolve(_ source: String?) -> ResolvedImageSource {
        guard let imageSource = ImageURLBuilder.makeSource(path: source) else { return .failure }
        switch imageSource {
        case let .remote(url):
            return .remote(url)
        case let .embedded(data):
            let key = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() as NSString
            if let image = cache.object(forKey: key) {
                return .embedded(image)
            }
            guard let image = SDImageCodersManager.shared.decodedImage(with: data, options: nil)
            else { return .failure }
            let cost = image.cgImage.map { $0.bytesPerRow * $0.height } ?? data.count
            cache.setObject(image, forKey: key, cost: cost)
            return .embedded(image)
        }
    }
}
