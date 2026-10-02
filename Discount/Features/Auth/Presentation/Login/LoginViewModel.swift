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
    private(set) var state: ViewState = .idle
    private let sessionStore: SessionStore
    
    init(sessionStore: SessionStore){
        self.sessionStore = sessionStore
    }

    var isLoading: Bool {
        state == .loading
    }

    var errorMessage: String? {
        if case let .error(message) = state {
            return message
        }
        return nil
    }

    var isFormValid: Bool {
        validate(email: email, password: password).isValid
    }

    func login(appState: AppState) async {
        guard !isLoading else { return }

        state = .idle

        let validation = validate(email: email, password: password)
        guard validation.isValid else {
            state = .error(validation.message)
            return
        }

        state = .loading
        defer {
            state = .loaded
        }
        do {
            try await sessionStore.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            appState.loginCompleted()
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}

