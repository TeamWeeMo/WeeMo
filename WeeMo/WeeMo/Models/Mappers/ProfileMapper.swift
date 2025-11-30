//
//  ProfileMapper.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation

// MARK: - Profile Mapper

extension ProfileDTO {
    /// DTO → Domain Model 변환
    func toDomain() -> Profile {
        return Profile(
            userId: userId,
            email: email,
            nick: nick,
            profileImage: profileImage,
            gender: gender,
            birthDay: birthDay ?? "",
            followers: followers.toDomain(),
            following: following.toDomain(),
            posts: posts
        )
    }
}
