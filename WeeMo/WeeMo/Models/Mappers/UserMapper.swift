//
//  UserMapper.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation

// MARK: - User Mapper

extension UserDTO {
    /// DTO → Domain Model 변환
    func toDomain() -> User {
        return User(
            userId: userId,
            nickname: nick,
            profileImageURL: profileImage
        )
    }
}

extension Array where Element == UserDTO {
    /// DTO 배열 → Domain Model 배열 변환
    func toDomain() -> [User] {
        return map { $0.toDomain() }
    }
}
