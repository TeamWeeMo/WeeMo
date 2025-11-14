//
//  CommentDTO.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation

// MARK: - Comment DTOs

/// 댓글 DTO
struct CommentDTO: Decodable {
    let commentId: String
    let content: String
    let createdAt: String
    let creator: UserDTO
    let replies: [CommentDTO]

    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content
        case createdAt
        case creator
        case replies
    }
}

/// 댓글 목록 응답
struct CommentListDTO: Decodable {
    let data: [CommentDTO]
}
