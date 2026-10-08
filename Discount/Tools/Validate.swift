//
//  Validate.swift
//  Discount
//
//  Created by Malik Alijanov on 24.09.26.
//

import Foundation

func validate(email: String, password: String? = nil) -> (isValid: Bool, message: String) {
    let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedEmail.isEmpty else {
        return (false, "E-poçt daxil edilməlidir.")
    }
    guard trimmedEmail.unicodeScalars.allSatisfy({ $0.isASCII }) else {
        return (false, "E-poçt ünvanında yalnız ingilis hərfləri, rəqəmlər və uyğun simvollar istifadə edin.")
    }

    let emailPattern = #"\A[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,63}\z"#
    guard trimmedEmail.utf8.count <= 254,
          let separator = trimmedEmail.firstIndex(of: "@"),
          trimmedEmail[..<separator].utf8.count <= 64,
          trimmedEmail.range(of: emailPattern, options: .regularExpression) != nil
    else {
        return (false, "Düzgün e-poçt daxil edin. Məsələn: ad@example.com")
    }

    if let password = password {
        guard password.count >= 6 else {
            return (false, "Şifrə ən azı 6 simvol olmalıdır.")
        }
    }
    return (true,"")
}
