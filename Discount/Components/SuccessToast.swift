//
//  SuccessToastModifier.swift
//  Discount
//
//  Created by Malik Alijanov on 08.10.26.
//

import SwiftUI

extension View {
    func successToast(message: Binding<String?>) -> some View {
        modifier(SuccessToastModifier(message: message))
    }
}

private struct SuccessToastModifier: ViewModifier {
    @Binding var message: String?
    private let displayDuration: Duration = .seconds(3)

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let message, !message.isEmpty {
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .accessibilityHidden(true)
                        Text(message)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .padding(AppSpacing.xs)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Bildirişi bağla")
                    }
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appSuccess)
                    .padding(AppSpacing.md)
                    .background(
                        Color.appSuccessBackground,
                        in: RoundedRectangle(cornerRadius: AppRadius.message)
                    )
                    .shadow(color: Color.appShadow.opacity(0.12), radius: 8, y: 4)
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.sm)
                    .accessibilityIdentifier("success-toast")
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: message)
            .task(id: message) {
                guard let displayedMessage = message else { return }
                do {
                    try await Task.sleep(for: displayDuration)
                } catch { return }
                guard !Task.isCancelled, message == displayedMessage else { return }
                dismiss()
            }
            .onDisappear {
                if message != nil { dismiss() }
            }
    }

    private func dismiss() {
        message = nil
    }
}
