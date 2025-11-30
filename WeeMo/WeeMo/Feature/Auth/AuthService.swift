//
//  AuthServicing.swift
//  WeeMo
//
//  Created by Lee on 11/14/25.
//

import Foundation

// Testable한 코드를 위한 protocol
protocol AuthServicing {
    func login(email: String, password: String) async throws -> AuthDTO

    func validateEmail(email: String) async throws -> ServerResponseDTO

    func join(email: String, password: String, nickname: String) async throws -> AuthDTO

    func refreshAccessToken() async throws -> RefreshTokenDTO

    func kakaoLogin(accessToken: String) async throws -> AuthDTO
}

struct AuthService: AuthServicing {
    private let networkService: NetworkService

    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }

    func login(email: String, password: String) async throws -> AuthDTO {
        try await networkService.request(
            AuthRouter.login(email: email, password: password),
            responseType: AuthDTO.self
        )
    }

    func validateEmail(email: String) async throws -> ServerResponseDTO {
        try await networkService.request(
            AuthRouter.emailValidation(email: email),
            responseType: ServerResponseDTO.self
        )
    }

    func join(email: String, password: String, nickname: String) async throws -> AuthDTO {
        try await networkService.request(
            AuthRouter.join(email: email, password: password, nickname: nickname),
            responseType: AuthDTO.self
        )
    }

    func refreshAccessToken() async throws -> RefreshTokenDTO {
        // TokenManager로부터 refreshToken 가져오기
        guard let refreshToken = TokenManager.shared.refreshToken else {
            throw NetworkError.refreshTokenExpired
        }

        // AuthRouter.refreshToken 호출
        return try await networkService.request(
            AuthRouter.refreshToken(refreshToken: refreshToken),
            responseType: RefreshTokenDTO.self
        )
    }

    func kakaoLogin(accessToken: String) async throws -> AuthDTO {
        try await networkService.request(
            AuthRouter.loginKakao(oauthToken: accessToken),
            responseType: AuthDTO.self
        )
    }
}
