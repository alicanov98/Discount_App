//
//  PrimaryButton.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var backgroundColor: Color = .appPrimary
    var textColor: Color = .appOnPrimary
    var borderColor: Color = .appTransparent
    var borderWidth: CGFloat = 0
    var cornerRadius: CGFloat = AppRadius.control
    var height: CGFloat = 52
    var isLoading = false
    var isDisable = false
    let action: () -> Void

    @Environment(\.isEnabled) private var parentEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(textColor)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(AppTypography.button)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(textColor)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.controlVertical)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisable || isLoading)
        .opacity(isDisable || !parentEnabled ? 0.5 : 1)
        .accessibilityValue(isLoading ? Text("Yüklənir") : Text(""))
    }
}

#Preview {
    VStack {
        PrimaryButton(title: "Daxil ol") {}
        PrimaryButton(title: "Daxil ol", isLoading: true) {}
        PrimaryButton(title: "Daxil ol", isDisable: true) {}
        PrimaryButton(title: "Parent disabled") {}.disabled(true)
    }
    .padding()
}
