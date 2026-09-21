//
//  InputFieldType.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import SwiftUI

enum InputFieldType {
    case text
    case email
    case phone
    case password
    case number
    
    var keyboardType: UIKeyboardType {
        switch self {
        case .text,.password:
                .default
        case .email:
                .emailAddress
        case .phone:
                .phonePad
        case .number:
                .numberPad
        }
    }
    
    var contnetType: UITextContentType? {
        switch self {
        case .email:
           return .emailAddress
        case .phone:
            return .telephoneNumber
        case .password:
            return .password
        case .number, .text:
            return nil
        }
        }
    
    var isSecure: Bool {
        self == .password
    }
    
 
    
}
