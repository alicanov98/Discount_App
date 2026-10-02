//
//  ResetPasswordView.swift
//  Discount
//
//  Created by Malik Alijanov on 26.09.26.
//

import SwiftUI

struct ResetPasswordView: View {
    @State private var viewModel: ResetPasswordViewModel

    init(sessionStore: SessionStore) {
        _viewModel = State(initialValue: ResetPasswordViewModel(sessionStore: sessionStore))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Şifrənizi yeniləyin")
                    .font(.title)
                    .fontWeight(.semibold)

                InputField(title: "Yeni Şifrı", placeholder: "Yeni şifrə daxil edin", type: .email, text: $viewModel.password, errorMessage: viewModel.errorMessage)
                PrimaryButton(
                    title: "Daxil ol",
                    borderColor: .appBorder
                ) {
                    Task {
                        await viewModel.resetPassword()
                    }
                }
            }
        }
    }
}

#Preview {
    let container = AppContainer()

    ResetPasswordView(sessionStore: container.sessionStore)
}
