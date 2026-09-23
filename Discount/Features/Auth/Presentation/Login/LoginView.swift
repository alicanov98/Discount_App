//
//  LoginView.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import SwiftUI



struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: LoginViewModel
    
    init(sessionStore:SessionStore) {
        _viewModel = State(
            initialValue: LoginViewModel(sessionStore: sessionStore)
        )
    }
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        NavigationStack {
            VStack(spacing:16) {
                Text("\(viewModel.selectedAccountType.rawValue) hesabı")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Picker ("Hesab növü",selection: $viewModel.selectedAccountType) {
                    ForEach(AccountType.allCases) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
                InputField(title: "E-poct", placeholder: "Email daxil edin", type: .email,text: $viewModel.email,errorMessage: viewModel.errorMessage)
                InputField(title: "Password", placeholder: "Password", type: .password,text: $viewModel.password, errorMessage: viewModel.errorMessage)
                HStack {
                    Spacer()
                        NavigationLink{
                            ForgotPasswordView()
                        }label: {
                            Text("Şifrəni unutdum")
                        }
                }
                PrimaryButton(
                    title:"Daxil ol",
                    borderColor: .black) {
                        Task{
                           await viewModel.login(appState: appState)
                        }
                    }
                HStack(spacing:3){
                    Text("Hesabın yoxdur?")
                    NavigationLink{
                        RegisterView()
                    }label: {
                        Text("Qeydiyyatdan keç")
                    }
                }
               
            }
            .padding()
            .navigationTitle("Giris")
        }
    }
}

#Preview {
    let tokenStore = KeychainService(
        service: "DiscountPreview"
    )

    let networkService = DefaultNetworkService(
        tokenStore: tokenStore
    )

    let authRepository = AuthRepository(
        networkService: networkService
    )

    let sessionStore = SessionStore(
        authRepository: authRepository,
        tokenStore: tokenStore
    )

    LoginView(
        sessionStore: sessionStore
    )
    .environment(
        AppState(tokenStore: tokenStore,sessionStore: sessionStore)
    )
}
