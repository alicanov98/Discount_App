//
//  ResetPasswordViewModel.swift
//  Discount
//
//  Created by Malik Alijanov on 26.09.26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ResetPasswordViewModel {
    private let token: String
    private let sessionStore: SessionStore
    var password = ""
    private(set) var state: ViewState = .idle
    private(set) var successMessage: String?

    init(sessionStore: SessionStore, token: String) {
        self.sessionStore = sessionStore
        self.token = token.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isLoading: Bool { state == .loading }
    var errorMessage: String? {
        if case let .error(message) = state { return message }
        return nil
    }
    var isFormValid: Bool { !token.isEmpty && password.count >= 6 }

    func dismissSuccessMessage() {
        successMessage = nil
    }

    func resetPassword() async {
        guard !isLoading else { return }
        successMessage = nil
        guard !token.isEmpty else {
            state = .error("Şifrə bərpa tokeni tapılmadı. Yeni bərpa linki istə.")
            return
        }
        guard password.count >= 6 else {
            state = .error("Şifrə ən azı 6 simvol olmalıdır.")
            return
        }
        state = .loading
        do {
            let response = try await sessionStore.resetPassword(token: token, password: password)
            guard response.data.success else {
                state = .error(response.data.message)
                return
            }
            successMessage = response.data.message
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
