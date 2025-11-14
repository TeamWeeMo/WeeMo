//
//  FollowDTO.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation

// MARK: - Follow DTOs

/// 팔로우/언팔로우 응답
struct FollowStatusDTO: Decodable {
    let followStatus: Bool

    enum CodingKeys: String, CodingKey {
        case followStatus = "follow_status"
    }
}
