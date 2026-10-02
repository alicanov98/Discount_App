//
//  ResetPasswordViewModel.swift
//  Discount
//
//  Created by Malik Alijanov on 26.09.26.
//

import Foundation

@MainActor
@Observable
final class ResetPasswordViewModel {
    private var token = ""
    var password = ""
    private(set) var errorMessage: String?

    private(set) var isLoading = false

    private let sessionStore: SessionStore

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }

    var isFormValid: Bool {
        !password.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func resetPassword() async {
        errorMessage = nil

        isLoading = true
        defer { isLoading = false }

        do {
            try await sessionStore.resetPassword(token: token, password: password.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
