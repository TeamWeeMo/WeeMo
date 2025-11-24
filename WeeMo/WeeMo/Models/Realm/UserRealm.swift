//
//  UserRealm.swift
//  WeeMo
//
//  Created by 차지용 on 11/20/25.
//

import Foundation
import RealmSwift

// MARK: - Realm User Model

/// Realm용 유저 모델
class UserRealm: Object {
    @Persisted var userId: String = ""
    @Persisted var nickname: String = ""
    @Persisted var profileImage: String? = nil
    @Persisted var email: String = ""
    @Persisted var createdAt: Date = Date()

    override static func primaryKey() -> String? {
        return "userId"
    }

    /// User 모델로 변환
    func toUser() -> User {
        return User(
            userId: userId,
            nickname: nickname,
            profileImageURL: profileImage
        )
    }

    /// UserDTO로부터 생성
    convenience init(from dto: UserDTO) {
        self.init()
        self.userId = dto.userId
        self.nickname = dto.nick
        self.profileImage = dto.profileImage
        self.email = ""
        self.createdAt = Date()
    }
}
