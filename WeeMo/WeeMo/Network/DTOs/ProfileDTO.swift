//
//  ProfileDTO.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation

// MARK: - Profile DTOs

/// 프로필 조회 응답
struct ProfileDTO: Decodable {
    let userId: String
    let email: String
    let nick: String
    let profileImage: String?
    let phoneNum: String?
    let gender: String?
    let birthDay: String?
    let info1: String?
    let info2: String?
    let info3: String?
    let info4: String?
    let info5: String?
    let followers: [UserDTO]
    let following: [UserDTO]
    let posts: [String]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case nick
        case profileImage
        case phoneNum
        case gender
        case birthDay
        case info1, info2, info3, info4, info5
        case followers
        case following
        case posts
    }
}
