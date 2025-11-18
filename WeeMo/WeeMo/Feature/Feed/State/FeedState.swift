//
//  FeedState.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/15/25.
//

import Foundation

// MARK: - Feed State

struct FeedState: Equatable {
    // 데이터
    var feeds: [Feed] = []
    var nextCursor: String? = nil

    // 로딩 상태
    var isLoading: Bool = false
    var isRefreshing: Bool = false
    var isLoadingMore: Bool = false

    // 에러
    var errorMessage: String? = nil

    // 네비게이션
    var selectedFeed: Feed? = nil
    var isShowingEditView: Bool = false

    // MARK: - Computed Properties

    /// 빈 상태 여부
    var isEmpty: Bool {
        feeds.isEmpty && !isLoading
    }

    /// 더 불러올 데이터가 있는지
    var hasMore: Bool {
        // nextCursor가 nil, 빈 문자열, "0"이 아닌 경우에만 true
        guard let cursor = nextCursor else { return false }
        return !cursor.isEmpty && cursor != "0"
    }
}
