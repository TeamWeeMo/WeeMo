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

        // 모든 파일 경로를 풀 URL로 변환
        let imageURLs = files.map { FileRouter.fileURL(from: $0) }

        return Feed(
            id: postId,
            imageURLs: imageURLs,
            content: content,
            creator: creator.toDomain(),
            createdAt: date,
            likes: likes,
            commentCount: commentCount
        )
    }
}
