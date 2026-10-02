//
//  LoginView.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppContainer.self) private var appContainer
    @State private var viewModel: LoginViewModel

    init(sessionStore: SessionStore) {
        _viewModel = State(
            initialValue: LoginViewModel(sessionStore: sessionStore)
        )
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    accountTypePicker(selection: $viewModel.selectedAccountType)
                    fields(email: $viewModel.email, password: $viewModel.password)
                    forgotPasswordLink
                    statusSection
                    registerLink
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Giriş")
        }
    }
}

// MARK: - Subviews

private extension LoginView {
    var header: some View {
        Text("\(viewModel.selectedAccountType.selectedType) hesabı")
            .font(.title)
            .fontWeight(.semibold)
    }

    func accountTypePicker(selection: Binding<AccountType>) -> some View {
        Picker("Hesab növü", selection: selection) {
            ForEach(AccountType.allCases) { type in
                Text(type.selectedType).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    func fields(email: Binding<String>, password: Binding<String>) -> some View {
        InputField(
            title: "E-poçt",
            placeholder: "E-poçt daxil edin",
            type: .email,
            text: email,
            errorMessage: nil
        )

        InputField(
            title: "Şifrə",
            placeholder: "Şifrə daxil edin",
            type: .password,
            text: password,
            errorMessage: nil
        )
    }

    var forgotPasswordLink: some View {
        HStack {
            Spacer()
            NavigationLink {
                ForgotPasswordView(sessionStore: appContainer.sessionStore)
            } label: {
                Text("Şifrəni unutdum")
            }
        }
    }

    // MARK: State-driven section (error + button)

    @ViewBuilder
    var statusSection: some View {
        switch viewModel.state {
        case .idle, .loaded, .empty:
            loginButton(title: "Daxil ol")

        case .loading:
            loginButton(title: "Daxil olunur...")
                .disabled(true)
            ProgressView()

        case let .error(message):
            Text(message)
                .font(.callout)
                .foregroundStyle(Color.appDanger)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            loginButton(title: "Daxil ol")
        }
    }

    func loginButton(title: String) -> some View {
        PrimaryButton(title: title, borderColor: .appBorder) {
            Task {
                await viewModel.login(appState: appState)
            }
        }
    }

    var registerLink: some View {
        HStack(spacing: 3) {
            Text("Hesabın yoxdur?")
            NavigationLink {
                RegisterView(
                    userRole: viewModel.selectedAccountType.rawValue,
                    sessionStore: appContainer.sessionStore
                )
            } label: {
                Text("Qeydiyyatdan keç")
            }
        }
    }
}

#Preview {
    let container = AppContainer()

    LoginView(sessionStore: container.sessionStore)
        .environment(container)
        .environment(container.appState)
        .environment(container.sessionStore)
}
