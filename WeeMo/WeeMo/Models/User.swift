//
//  User.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/12/25.
//

import Foundation

// MARK: - User Model

struct User: Hashable, Identifiable {
    let id = UUID()
    let userId: String
    let nickname: String
    let profileImageURL: String? // 변수명 변경 예정
}
