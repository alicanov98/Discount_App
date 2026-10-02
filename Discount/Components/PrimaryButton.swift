//
//  PrimaryButton.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import SwiftUI

struct PrimaryButton:View {
    let title: String

    var backgroundColor: Color = .appPrimary
    var textColor: Color = .appOnPrimary
    var borderColor: Color = .appTransparent
    var borderWidth: CGFloat = 0
    var cornerRadius: CGFloat = 16
    var height: CGFloat = 52
    var isLoading: Bool = false
    var isDisable: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action:action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(textColor)
                }else {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(textColor)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background{
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        borderColor,
                        lineWidth: borderWidth
                    )
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisable || isLoading)
        .opacity(isDisable ? 0.5 : 1)

    }
}

#Preview {
    PrimaryButton(title: "Test", backgroundColor: .appDanger, textColor: .appOnPrimary) {
        print("Test")
    }
}
