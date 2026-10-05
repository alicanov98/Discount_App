//
//  RegisterView.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import SwiftUI

struct RegisterView: View {
    let userRole: String

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RegisterViewModel

    private var isPersonalAccount: Bool {
        userRole == AccountType.user.rawValue
    }

    init(userRole: String, sessionStore: SessionStore) {
        self.userRole = userRole
        _viewModel = State(
            initialValue: RegisterViewModel(
                sessionStore: sessionStore,
                userRole: userRole
            )
        )
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                header
                fields(
                    name: $viewModel.name,
                    email: $viewModel.email,
                    password: $viewModel.password
                )
                statusSection
                    loginLink
                        .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .disabled(viewModel.isLoading)
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, AppSpacing.lg)
        }
        .background(Color.appBackground)
        .foregroundStyle(Color.appTextPrimary)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Qeydiyyat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            #if DEBUG
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        NetworkingDebugView()
                    } label: {
                        Image(systemName: "network")
                    }
                }
            #endif
        }
    }
}

// MARK: - Subviews

private extension RegisterView {
    var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(isPersonalAccount ? "ŞƏXSİ HESAB" : "BİZNES HESAB")
                .font(AppTypography.largeTitle)

            Text("Yeni fürsətlərə salam de.")
                .font(AppTypography.title)

            Text("Kəşf hesabınla fürsətlər bir addım yaxındadır.")
                .font(AppTypography.body)
        }
    }

    func fields(
        name: Binding<String>,
        email: Binding<String>,
        password: Binding<String>
    ) -> some View {
        VStack(spacing: AppSpacing.controlVertical) {
            InputField(
                title: isPersonalAccount ? "Ad və soyad" : "Biznes adı",
                placeholder: isPersonalAccount ? "Adın və soyadın" : "Biznesin adı",
                text: name,
                errorMessage: nil
            )

            InputField(
                title: "E-poçt",
                placeholder: "sen@example.com",
                type: .email,
                text: email,
                errorMessage: nil
            )

            InputField(
                title: "Şifrə",
                placeholder: "Ən az 6 simvol",
                type: .password,
                text: password,
                errorMessage: nil
            )
        }
    }

    var statusSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(AppTypography.body)
                    .foregroundStyle(Color.appDanger)
                    .fixedSize(horizontal: false, vertical: true)
            }
            PrimaryButton(title: "Qeydiyyat", isLoading: viewModel.isLoading) {
                Task { await viewModel.register(appState: appState) }
            }
        }
    }

    var loginLink: some View {
        HStack(spacing: 3) {
            Text("Hesabım var.")
            Button("Daxil ol") {
                dismiss()
            }
        }
    }
}

#Preview {
    let container = AppContainer()

    let userRole = AccountType.user.rawValue

    NavigationStack {
        RegisterView(userRole: userRole, sessionStore: container.sessionStore)
    }
    .environment(container.appState)
}
