//
//  FeedIntent.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/15/25.
//

import Foundation

// MARK: - Feed Intent

enum FeedIntent {
    // 라이프사이클
    case onAppear

    // 사용자 액션
    case selectFeed(Feed)
    case deselectFeed
    case createNewFeed
    case dismissEditView
    case loadMore

    // 내부 이벤트 (사용하지 않음 - 직접 State 업데이트)
    case loadFeedsSuccess([Feed])
    case loadFeedsFailed(Error)
    case loadMoreSuccess([Feed], nextCursor: String?)
    case loadMoreFailed(Error)
}
