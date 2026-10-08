//
//  ResetPasswordView.swift
//  Discount
//
//  Created by Malik Alijanov on 26.09.26.
//


import SwiftUI

struct ResetPasswordView: View {
    @State private var viewModel: ResetPasswordViewModel

    init(sessionStore: SessionStore, token: String) {
        _viewModel = State(initialValue: ResetPasswordViewModel(sessionStore: sessionStore, token: token))
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Şifrənizi yeniləyin")
                    .font(AppTypography.title)
                InputField(
                    title: "Yeni şifrə",
                    placeholder: "Ən az 6 simvol",
                    type: .password,
                    text: $viewModel.password,
                    errorMessage: viewModel.errorMessage
                )
                PrimaryButton(title: "Şifrəni yenilə", isLoading: viewModel.isLoading) {
                    Task { await viewModel.resetPassword() }
                }
            }
            .disabled(viewModel.isLoading)
            .padding(AppSpacing.lg)
        }
        .background(Color.appBackground)
        .foregroundStyle(Color.appTextPrimary)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Yeni şifrə")
        .navigationBarTitleDisplayMode(.inline)
        .successToast(message: Binding(
            get: { viewModel.successMessage },
            set: { _ in viewModel.dismissSuccessMessage() }
        ))
    }
}

#Preview {
    let container = AppContainer()
    ResetPasswordView(sessionStore: container.sessionStore, token: "preview-token")
}
