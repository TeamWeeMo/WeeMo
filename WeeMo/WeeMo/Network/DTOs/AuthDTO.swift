//
//  AuthDTO.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation

// MARK: - Auth DTOs

/// 회원가입/로그인 응답
struct AuthDTO: Decodable {
    let userId: String
    let email: String
    let nick: String
    let profileImage: String?  // 회원가입 시 프로필 이미지가 없을 수 있음
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case nick
        case profileImage
        case accessToken
        case refreshToken
    }
}

/// 토큰 갱신 응답 (accessToken, refreshToken만 포함)
struct RefreshTokenDTO: Decodable {
    let accessToken: String
    let refreshToken: String
}
