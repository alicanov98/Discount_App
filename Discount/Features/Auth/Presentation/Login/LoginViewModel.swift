//
//  LoginViewModel.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation
import Observation


@MainActor
@Observable
final class LoginViewModel {
    var selectedAccountType: AccountType = .user {
        didSet {
            #if DEBUG
            email = selectedAccountType == .user ? "demo@kesf.example" : "business@kesf.example"
            #endif
        }
    }
    #if DEBUG
    var email =  "demo@kesf.example"
    var password = "KesfDemo2026!"
    #else
    var email = ""
    var password = ""
    #endif
    private(set) var errorMessage: String?
    private(set) var isLoading = false
    
    private let sessionStore: SessionStore
    
    init(sessionStore: SessionStore){
        self.sessionStore = sessionStore
    }
    
    var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }
    
    func login(appState:AppState)async {
        errorMessage = nil
        let validation = validate(email: email, password: password)
        guard validation.isValid else {
            errorMessage = validation.message
             return
         }
         
        isLoading = true
         defer { isLoading =  false}
       
         do{
             try await sessionStore.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
             )
             appState.loginCompleted()
         }catch {
             errorMessage = error.localizedDescription
         }
  
       
    }
    
  
}

//**Biznes hesabı:**
//- Email: `business@kesf.example`
//- Şifrə: `KesfDemo2026!`
//
//**Adi istifadəçi hesabı:**
//- Email: `demo@kesf.example`
//- Şifrə: `KesfDemo2026!`
