//
//  AppLoadingView.swift
//  Discount
//
//  Created by Malik Alijanov on 08.10.26.
//

import SwiftUI

struct AppLoadingView: View {
    enum Placement {
        case content
        case inline
    }

    static let title = "Loading ..."
    var placement: Placement = .content

    var body: some View {
        Group {
            switch placement {
            case .content:
                label
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
            case .inline:
                label
            }
        }
    }

    private var label: some View {
        Text(Self.title)
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.updatesFrequently)
    }
}

#Preview {
    AppLoadingView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
}
