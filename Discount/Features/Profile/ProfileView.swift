//
//  ProfileView.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(AppState.self) private var appState
    @State private var viewModel = ProfileViewModel()
    
    
    var body: some View {
        Button {
            Task{
                await  viewModel.logout(using: sessionStore, updating: appState)
            }
        }label: {
            if viewModel.isLoggingOut {
                ProgressView()
            }else {
                Text("Hesabdan cix")
            }
        }
        .disabled(viewModel.isLoggingOut)
        .alert(
            "Xəta baş verdi",
             isPresented: $viewModel.isShowingError
        ){
            Button("Bagla",role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Hesabdan çıxış zamanı xəta baş verdi.")
        }
    }
    

}

//#Preview {
//    ProfileView()
//}
