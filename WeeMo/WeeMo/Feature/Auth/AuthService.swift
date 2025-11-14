//
//  AuthServicing.swift
//  WeeMo
//
//  Created by Lee on 11/14/25.
//

import Foundation

// Testable한 코드를 위한 protocol
protocol AuthServicing {
    func login(email: String, password: String) async throws -> LoginDTO
}

struct AuthService: AuthServicing {
    private let networkService: NetworkService

    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }

    func login(email: String, password: String) async throws -> LoginDTO {
        try await networkService.request(
            AuthRouter.login(email: email, password: password),
            responseType: LoginDTO.self
        )
    }
}
