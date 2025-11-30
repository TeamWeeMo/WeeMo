//
//  Profile.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/12/25.
//

import Foundation

// MARK: - Profile Model

struct Profile: Hashable {
    let userId: String // id
    let email: String?
    let nick: String
    let profileImage: String?
    let gender: String?
    let birthDay: String     // "yyyyMMdd" or nil
    let followers: [User]    // 서버에 따라 생략될 수 있으니 옵셔널
    let following: [User]
    let posts: [String]
}
