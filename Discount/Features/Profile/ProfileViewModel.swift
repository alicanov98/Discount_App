//
//  ProfileViewModel.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation
import Observation


@MainActor
@Observable
final class ProfileViewModel {
      var isLoggingOut = false
      var errorMessage: String?
      var isShowingError = false
    
    
    func logout(using sessionStore: SessionStore, updating appState:AppState) async {
         guard !isLoggingOut else {
             return
         }
         
         isLoggingOut = true
         errorMessage = nil
         
         defer {
             isLoggingOut = false
         }
            do{
                 try await sessionStore.logout()
                 appState.logoutCompleted()

            }catch{
                errorMessage = error.localizedDescription
                isShowingError = true
            }
        }
    }

