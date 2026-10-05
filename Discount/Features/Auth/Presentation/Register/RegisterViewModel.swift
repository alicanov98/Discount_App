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
    let userRole: String

    private(set) var state: ViewState = .idle

    var errorMessage: String {
        if case let .error(message) = state {
            return message
        } else {
            return ""
        }
    }

    var isLoading: Bool {
        state == .loading
    }

    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            validate(email: email, password: password).isValid
    }

    private let sessionStore: SessionStore

    init(sessionStore: SessionStore, userRole: String) {
        self.userRole = userRole
        self.sessionStore = sessionStore
    }

    func register(appState: AppState) async {
        guard !isLoading else { return }

        state = .idle

        let validation = validate(email: email, password: password)
        guard validation.isValid else {
            state = .error(validation.message)
            return
        }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state = .error("Ad daxil edilməlidir.")
            return
        }
        guard AccountType(rawValue: userRole) != nil else {
            state = .error(AccountTypeError.unsupportedValue(userRole).localizedDescription)
            return
        }
        state = .loading

        do {
            try await sessionStore.register(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                role: userRole
            )
            state = .loaded
            appState.loginCompleted()
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
