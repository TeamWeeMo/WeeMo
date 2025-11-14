//
//  PostMapper.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation

// MARK: - Post Mapper

extension PostDTO {
    /// DTO → Domain Model 변환 (Feed)
    func toFeed() -> Feed {
        // ISO8601 날짜 파싱
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = dateFormatter.date(from: createdAt) ?? Date()

        return Feed(
            id: postId,
            imageURL: files.first ?? "",
            content: content,
            creator: creator.toDomain(),
            createdAt: date,
            likes: likes,
            commentCount: commentCount
        )
    }
}
