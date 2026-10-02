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
            VStack(alignment: .leading, spacing: 16) {
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
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
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
        VStack(alignment: .leading, spacing: 8) {
            Text(isPersonalAccount ? "ŞƏXSİ HESAB" : "BİZNES HESAB")
                .font(AppTypography.largeTitle)

            Text("Yeni fürsətlərə salam de.")
                .font(AppTypography.title)

            Text("Kəşf hesabınla fürsətlər bir addım yaxındadır.")
                .font(AppTypography.font(size: 16, weight: .regular))
        }
    }

    func fields(
        name: Binding<String>,
        email: Binding<String>,
        password: Binding<String>
    ) -> some View {
        VStack(spacing: 12) {
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
                placeholder: "Ən az 8 simvol",
                type: .password,
                text: password,
                errorMessage: nil
            )
        }
    }

    // MARK: State-driven section (error + button)

    @ViewBuilder
    var statusSection: some View {
        switch viewModel.state {
        case .idle, .loaded, .empty:
            registerButton(title: "Qeydiyyat")

        case .loading:
            registerButton(title: "Qeydiyyat edilir...")
                .disabled(true)
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }

        case let .error(message):
            Text(message)
                .font(.callout)
                .foregroundStyle(Color.appDanger)
                .frame(maxWidth: .infinity, alignment: .leading)
            registerButton(title: "Qeydiyyat")
        }
    }

    func registerButton(title: String) -> some View {
        PrimaryButton(title: title) {
            Task {
                await viewModel.register(appState: appState)
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
