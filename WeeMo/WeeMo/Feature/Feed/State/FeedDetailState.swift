//
//  FeedDetailState.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/15/25.
//

import Foundation

// MARK: - Feed Detail State

struct FeedDetailState {
    // 피드 데이터
    let feed: Feed

    // 인터랙션 상태
    var isLiked: Bool = false
    var likeCount: Int
    var commentCount: Int

    // 이미지 페이징
    var currentImageIndex: Int = 0

    // UI 상태
    var showCommentSheet: Bool = false

    // 로딩/에러
    var isLoading: Bool = false
    var errorMessage: String?

    // 초기화
    init(feed: Feed) {
        self.feed = feed
        self.likeCount = feed.likes.count
        self.commentCount = feed.commentCount
        // 현재 유저가 좋아요했는지 확인
        // TODO: 현재 유저 ID와 비교 필요
        self.isLiked = false
    }

    /// 현재 표시할 이미지 URL
    var currentImageURL: String {
        guard !feed.imageURLs.isEmpty else { return "" }
        // 안전한 인덱스 접근 (범위 체크)
        guard currentImageIndex >= 0 && currentImageIndex < feed.imageURLs.count else {
            return feed.imageURLs[0]
        }
        return feed.imageURLs[currentImageIndex]
    }

    /// 이미지가 여러 장인지 여부
    var hasMultipleImages: Bool {
        feed.imageURLs.count > 1
    }

    /// 상대적 시간 문자열
    var timeAgoString: String {
        feed.createdAt.timeAgoString()
    }
}
