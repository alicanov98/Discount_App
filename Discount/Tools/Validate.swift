//
//  Validate.swift
//  Discount
//
//  Created by Malik Alijanov on 24.09.26.
//

import Foundation

func validate(email:String,password: String) -> (isValid: Bool, message: String) {
    let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
    var errorMessage:String = ""
    guard !trimmedEmail.isEmpty else {
        errorMessage = "E-poct daxil edilmelidir."
        return (isValid:false,message:errorMessage)
    }
    
    guard trimmedEmail.contains("@") else {
        errorMessage = "Duzgun e-poct daxil edin."
        return (isValid:false,message:errorMessage)
    }
    
    guard password.count >= 6 else {
        errorMessage = "Sifre en azi 6 simvol olmalidir."
        return (isValid:false,message:errorMessage)
    }
    return (isValid:true,message:"")
}
