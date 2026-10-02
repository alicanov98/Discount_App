//
//  ForgotPasswordView.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import SwiftUI

struct ForgotPasswordView: View {
    @State private var viewModel: ForgotPasswordViewModel

    init(sessionStore: SessionStore) {
        _viewModel = State(initialValue: ForgotPasswordViewModel(sessionStore: sessionStore))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Şifrənizi yeniləmək üçün email daxil edin.")
                    .font(AppTypography.largeTitle)
                    .multilineTextAlignment(.center)

                InputField(
                    title: "E-poçt",
                    placeholder: "Email daxil edin",
                    type: .email,
                    text: $viewModel.email,
                    errorMessage: viewModel.errorMessage
                )

                PrimaryButton(
                    title: "Şifrəni yenilə",
                    borderColor: .appBorder
                ) {
                    Task {
                        await viewModel.forgetPassword()
                    }
                }
                message
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
        }
        .onDisappear {
            viewModel.clear()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    var message: some View {
        if let message = viewModel.successMessage, !message.isEmpty {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.appSuccess)

                Text(message)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(Color.appTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appSuccess.opacity(0.1))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appSuccess.opacity(0.25), lineWidth: 1)
            }
            .foregroundStyle(Color.appSuccess)
            .opacity(0.2)
        }
    }
}

#Preview {
    let container = AppContainer()

    ForgotPasswordView(sessionStore: container.sessionStore)
}
