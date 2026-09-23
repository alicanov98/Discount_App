//
//  HomeViewModel.swift
//  Discount
//
//  Created by Malik Alijanov on 21.09.26.
//

import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private let sessionStore: SessionStore
    private let homeRepository: any HomeRepositoryProtocol
    var isLoading = false
    var errorMessage: String?
    var isShowingError = false
    var user:User?
    var currentUser: User? {
            sessionStore.currentUser
        }
    
    init(
        sessionStore: SessionStore,
        homeRepository: any HomeRepositoryProtocol
    ) {
        self.sessionStore = sessionStore
        self.homeRepository = homeRepository
    }
    
    func refresh() async  {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        isShowingError = false
        
        defer {
            isLoading = false
        }
        
        do{
        try await sessionStore.refresh()
        } catch {
            print("Refresh error:", error.localizedDescription)
            isShowingError = true
        }
    }
    
    func me() async  {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        isShowingError = false
        
        defer {
            isLoading = false
        }
        
        do{
            let response = try await homeRepository.me()
            sessionStore.currentUser = response
            user = response
        }catch {
            print(error.localizedDescription)
            isShowingError = true
        }
    }
}
