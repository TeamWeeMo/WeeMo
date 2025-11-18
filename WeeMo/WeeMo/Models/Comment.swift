//
//  Comment.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/16/25.
//

import Foundation

// MARK: - Comment 데이터 모델

struct Comment: Identifiable, Hashable {
    let id: String           // comment_id
    let content: String
    let creator: User        // 댓글 작성자
    let createdAt: Date
}
