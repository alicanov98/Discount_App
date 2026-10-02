//
//  ForgotPasswordViewModel.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation

@MainActor
@Observable
final class ForgotPasswordViewModel {
    // MARK: - State

    var email = ""
    private(set) var state: ViewState = .idle
    private(set) var successMessage: String?

    private let sessionStore: SessionStore

    // MARK: - Derived

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
        validate(email: email).isValid
    }

    private var trimmedEmail: String {
        validate(email: email).message
    }

    // MARK: - Init

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }

    // MARK: - Actions

    func forgetPassword() async {
        guard !isLoading else { return }

        successMessage = nil

        let validation = validate(email: trimmedEmail)
        guard validation.isValid else {
            state = .error(validation.message)
            return
        }

        state = .loading

        do {
            let response = try await sessionStore.forgetPassword(email: trimmedEmail)
            successMessage = response.data.message
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func clear() {
        email = ""
        successMessage = nil
        state = .idle
    }
}
