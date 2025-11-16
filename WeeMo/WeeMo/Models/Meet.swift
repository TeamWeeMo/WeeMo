//
//  Meet.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/12/25.
//

import Foundation

struct Meet: Identifiable {
    let id = UUID()
    let postId: String // 서버에서 받은 실제 포스트 ID
    let title: String
    let date: String
    let location: String
    let address: String
    let price: String
    let participants: String
    let imageName: String
    let daysLeft: String
}
