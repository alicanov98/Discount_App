//
//  RegisterView.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import SwiftUI

struct RegisterView: View {
    var userRole:String
    
    @Environment(AppState.self) private var appState
    @State private var viewModel: RegisterViewModel
    @Environment(\.dismiss) private var dismiss
    
    private var userRoleType : Bool {
        userRole ==  AccountType.user.rawValue
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
        
        ScrollView {
               VStack(alignment: .leading) {
                   Text(userRoleType ? "ŞƏXSİ HESAB" : "BİZNES HESAB")
                       .font(AppTypography.largeTitle)

                   Text("Yeni fürsətlərə salam de.")
                       .font(AppTypography.title)

                   Text("Kəşf hesabınla fürsətlər bir addım yaxındadır.")
                       .font(AppTypography.font(size: 16,weight: .regular))

                   content
                       .padding(.top, 16)
               }
               .frame(maxWidth: .infinity, alignment: .leading)
               .padding(.horizontal, 20)
               .padding(.vertical, 24)
           }
           .navigationTitle("Qeydiyyat")
           .navigationBarTitleDisplayMode(.inline)
    }
    
    var content: some View {
        VStack (spacing: 12){
            InputField(title: "\(userRoleType ? "Ad və soyad" : "Bizness Ad")", placeholder: "Adın və soyadın", text: $viewModel.name,errorMessage: viewModel.errorMessage)
            InputField(title: "E-poçt", placeholder: "sen@example.com", text: $viewModel.email,errorMessage: viewModel.errorMessage)
            InputField(title: "Şifrə", placeholder: "Ən az 8 simvol", text: $viewModel.password,errorMessage: viewModel.errorMessage)
            PrimaryButton(title: "Qeydiyyat") {
                Task {
                    await viewModel.register(appState: appState)
                }
            }
            HStack(spacing: 3) {
                Text("Hesabım var.")

                Button("Daxil ol") {
                    dismiss()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    
}


//#Preview("İstifadəçi") {
//    NavigationStack {
//        RegisterView(userRole: AccountType.user.rawValue)
//    }
//}

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
    
    let userRole = AccountType.user.rawValue
    
    NavigationStack {
        RegisterView(userRole:userRole,sessionStore: sessionStore)
      }}
