//
//  AppTypography.swift
//  Discount
//
//  Created by Malik Alijanov on 23.09.26.
//

import SwiftUI

enum AppTypography {

    enum Weight {
        case regular
        case medium
        case semiBold
        case bold

        var fontName: String {
            switch self {
            case .regular:  "Inter-Regular"
            case .medium:   "Inter-Medium"
            case .semiBold: "Inter-SemiBold"
            case .bold:     "Inter-Bold"
            }
        }
    }

    static func font(
        size: CGFloat,
        weight: Weight = .regular,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        .custom(weight.fontName, size: size, relativeTo: textStyle)
    }

    // Tətbiqdə tez-tez istifadə olunan hazır stillər
    static let largeTitle = font(size: 32, weight: .bold, relativeTo: .largeTitle)
    static let title = font(size: 28, weight: .semiBold, relativeTo: .title)
    static let sectionTitle = font(size: 20, weight: .semiBold, relativeTo: .title3)
    static let body = font(size: 16)
    static let caption = font(size: 13, relativeTo: .caption)
    static let button = font(size: 16, weight: .semiBold)
}
