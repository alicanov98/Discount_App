//
//  HomeView.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack {
            Text(
                """
                Ad: \(viewModel.user?.name ?? "-")
                Email: \(viewModel.user?.email ?? "-")
                Role: \(viewModel.user?.role ?? "-")
                """
            )

            if viewModel.isLoading {
                ProgressView()
            }
        }
        .task {
            await viewModel.refresh()
            await viewModel.me()
        }
        .alert(
            "Xəta baş verdi",
            isPresented: $viewModel.isShowingError
        ) {
            Button("Bağla", role: .cancel) {
                viewModel.isShowingError = false
            }
        } message: {
            Text(
                viewModel.errorMessage
                ?? "Məlumatları yeniləmək mümkün olmadı."
            )
        }
    }
}

//#Preview {
//    let currentUser = User.mock
//    let currentUserBuisness = User.mockBusiness
//    
//    HomeView(currentUser: currentUser)
//}
