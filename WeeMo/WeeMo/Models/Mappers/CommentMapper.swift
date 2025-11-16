//
//  CommentMapper.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/16/25.
//

import Foundation

// MARK: - Comment Mapper

extension CommentDTO {
    /// DTO → Domain Model 변환
    func toDomain() -> Comment {
        return Comment(
            id: commentId,
            content: content,
            creator: creator.toDomain(),
            createdAt: createdAt.toDate() ?? Date()
        )
    }
}

extension Array where Element == CommentDTO {
    /// DTO 배열 → Domain Model 배열 변환
    func toDomain() -> [Comment] {
        return map { $0.toDomain() }
    }
}
