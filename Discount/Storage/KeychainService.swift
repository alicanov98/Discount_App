//
//  KeychainService.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

import Foundation
import Security

enum KeychainError: LocalizedError {
    case invalidData
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Məlumat Keychain üçün hazırlana bilmədi."

        case .unexpectedStatus(let status):
            return "Keychain xətası baş verdi. Status: \(status)"
        }
    }
}

final class KeychainService: TokenStore {

    private let service: String

    private let accessTokenAccount = "access_token"
    private let refreshTokenAccount = "refresh_token"

    init(
        service: String = Bundle.main.bundleIdentifier
            ?? "DefaultAppService"
    ) {
        self.service = service
    }

    var accessToken: String? {
        read(account: accessTokenAccount)
    }

    var refreshToken: String? {
        read(account: refreshTokenAccount)
    }

    func saveTokens(
        accessToken: String,
        refreshToken: String
    ) throws {
        do {
            try save(
                accessToken,
                account: accessTokenAccount
            )

            try save(
                refreshToken,
                account: refreshTokenAccount
            )
        } catch {
            try? clearTokens()
            throw error
        }
    }

    func clearTokens() throws {
        var firstError: Error?

        do {
            try delete(account: accessTokenAccount)
        } catch {
            firstError = error
        }

        do {
            try delete(account: refreshTokenAccount)
        } catch {
            if firstError == nil {
                firstError = error
            }
        }

        if let firstError {
            throw firstError
        }
    }
}

private extension KeychainService {

    func save(
        _ value: String,
        account: String
    ) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrService as String:
                service,

            kSecAttrAccount as String:
                account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            attributes as CFDictionary
        )

        if updateStatus == errSecItemNotFound {
            var newItem = query

            newItem[kSecValueData as String] = data

            newItem[kSecAttrAccessible as String] =
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly

            let addStatus = SecItemAdd(
                newItem as CFDictionary,
                nil
            )

            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(
                    addStatus
                )
            }

            return
        }

        guard updateStatus == errSecSuccess else {
            throw KeychainError.unexpectedStatus(
                updateStatus
            )
        }
    }

    func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrService as String:
                service,

            kSecAttrAccount as String:
                account,

            kSecReturnData as String:
                true,

            kSecMatchLimit as String:
                kSecMatchLimitOne
        ]

        var result: AnyObject?

        let status = SecItemCopyMatching(
            query as CFDictionary,
            &result
        )

        guard status == errSecSuccess else {
            return nil
        }

        guard
            let data = result as? Data,
            let value = String(
                data: data,
                encoding: .utf8
            )
        else {
            return nil
        }

        return value
    }

    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String:
                kSecClassGenericPassword,

            kSecAttrService as String:
                service,

            kSecAttrAccount as String:
                account
        ]

        let status = SecItemDelete(
            query as CFDictionary
        )

        guard
            status == errSecSuccess ||
            status == errSecItemNotFound
        else {
            throw KeychainError.unexpectedStatus(
                status
            )
        }
    }
}
