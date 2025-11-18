//
//  Feed.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/12/25.
//

import Foundation

// MARK: - Feed 데이터 모델 (임시)

struct Feed: Identifiable, Hashable {
    let id: String            // post_id
    let imageURLs: [String]   // 이미지 URL 배열 (여러 장 지원)
    let content: String
    let creator: User  // 피드게시글 작성 유저
    let createdAt: Date
    let likes: [String]       // 좋아요 배열 - 좋아요한 사람들 [String]
                              // 숫자 카운트만 쓰면 Int
    let commentCount: Int

    // MARK: - Computed Properties

    /// 대표 이미지 URL (리스트에서 사용)
    var thumbnailURL: String {
        imageURLs.first ?? ""
    }

    /// Pinterest Layout을 위한 계산된 높이 비율
    /// - Note: 실제 이미지 비율은 FeedCardView에서 동적으로 계산
    /// - 기본값: 1.0 (정사각형)
    var aspectRatio: CGFloat {
        return 1.0
    }

}
