//
//  UserDTO.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation

// MARK: - User DTOs

/// 유저 기본 정보 (검색, 댓글, 게시글 작성자 등에 공통으로 사용)
struct UserDTO: Decodable {
    let userId: String
    let nick: String
    let profileImage: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage
    }
}

/// 유저 검색 응답
struct UserSearchDTO: Decodable {
    let data: [UserDTO]
}
