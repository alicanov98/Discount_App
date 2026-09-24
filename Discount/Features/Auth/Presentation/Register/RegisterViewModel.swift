//
//  RegisterViewModel.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation

@MainActor
@Observable
final class RegisterViewModel {
    var name: String = ""
    var email: String = ""
    var password: String = ""
    var userRole:String

    private(set) var errorMessage: String?
    private(set) var isLoading = false
    
    var isFormValid:Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private let sessionStore: SessionStore
    
    init(sessionStore: SessionStore,userRole: String){
        self.userRole = userRole
        self.sessionStore = sessionStore
    }
    
    
    func register(appState:AppState) async {
        errorMessage = nil
        let validation = validate(email: email, password: password)
        guard validation.isValid else {
            errorMessage = validation.message
             return
         }
        isLoading = true
        defer { isLoading = false}
        
        do{
            try await sessionStore.register(name: name, email: email, password: password, role: userRole)
            appState.loginCompleted()
        }catch {
            errorMessage = error.localizedDescription
        }
    }
    

    
}
