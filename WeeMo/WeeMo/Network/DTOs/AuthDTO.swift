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
    let profileImage: String
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
