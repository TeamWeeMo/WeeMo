//
//  FeedDetailIntent.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/15/25.
//

import Foundation

// MARK: - Feed Detail Intent

enum FeedDetailIntent {
    // 라이프사이클
    case onAppear

    // 사용자 액션
    case toggleLike
    case openComments
    case closeComments
    case sharePost
    case showMoreMenu
    case navigateToProfile

    // 이미지 페이징
    case changeImagePage(Int)
}
