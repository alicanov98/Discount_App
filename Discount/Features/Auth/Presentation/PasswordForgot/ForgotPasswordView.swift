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
            VStack(spacing: AppSpacing.lg) {
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
                    isLoading: viewModel.isLoading
                ) {
                    Task {
                        await viewModel.forgetPassword()
                    }
                }
            }
            .disabled(viewModel.isLoading)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.lg)
        }
        .background(Color.appBackground)
        .foregroundStyle(Color.appTextPrimary)
        .navigationTitle("Şifrə bərpası")
        .navigationBarTitleDisplayMode(.inline)
        .successToast(message: Binding(
            get: { viewModel.successMessage },
            set: { _ in viewModel.dismissSuccessMessage() }
        ))
        .onDisappear {
            viewModel.clear()
        }
        .scrollDismissesKeyboard(.interactively)
    }

}

#Preview {
    let container = AppContainer()

    ForgotPasswordView(sessionStore: container.sessionStore)
}
