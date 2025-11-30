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
        // 모든 파일 경로를 풀 URL로 변환
        let imageURLs = files.map { FileRouter.fileURL(from: $0) }

        return Feed(
            id: postId,
            imageURLs: imageURLs,
            content: content,
            creator: creator.toDomain(),
            createdAt: createdAt.toDate() ?? Date(),
            likes: likes,
            commentCount: commentCount
        )
    }
}
