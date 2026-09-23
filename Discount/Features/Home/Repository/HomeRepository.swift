//
//  HomeRepository.swift
//  Discount
//
//  Created by Malik Alijanov on 21.09.26.
//

import Foundation

protocol HomeRepositoryProtocol {
    func me () async throws -> User
}

final class HomeRepository: HomeRepositoryProtocol {
    private let networkService: any NetworkServiceProtocol
    
    init(networkService: any NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    
    func me() async throws -> User {
        do{
            let response = try await networkService.request(HomeEndpoint.me, responseType: MeResponseData.self)
            return response.data
        }catch {
            print(error.localizedDescription, "Error")
            throw error
        }
    }
    
    
}
