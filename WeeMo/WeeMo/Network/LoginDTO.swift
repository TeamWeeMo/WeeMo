//
//  LoginDTO.swift
//  WeeMo
//
//  Created by Lee on 11/14/25.
//

import Foundation

struct LoginDTO: Decodable {
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
