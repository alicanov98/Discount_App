//
//  AuthRepositoryProtocol.swift
//  Discount
//
//  Created by Malik Alijanov on 18.09.26.
//

protocol AuthRepositoryProtocol {

    func login(
        email: String,
        password: String
    ) async throws -> LoginResponse
    
    func logout() async throws 
}
