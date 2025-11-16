//
//  SpaceListState.swift
//  WeeMo
//
//  Created by Reimos on 11/15/25
//

import Foundation

// MARK: - Space List State

/// SpaceListView의 모든 상태를 관리하는 구조체
struct SpaceListState {
    // MARK: - Data

    /// 서버에서 가져온 전체 공간 목록
    var allSpaces: [Space] = []

    /// 검색어
    var searchText: String = ""

    /// 선택된 카테고리
    var selectedCategory: SpaceCategory = .all

    // MARK: - UI State

    /// 로딩 중 여부
    var isLoading: Bool = false

    /// 에러 메시지
    var errorMessage: String?

    // MARK: - Computed Properties

    /// 필터링된 공간 목록 (카테고리 + 검색어)
    var filteredSpaces: [Space] {
        // 1. 카테고리 필터링
        let categoryFiltered = selectedCategory == .all
            ? allSpaces
            : allSpaces.filter { $0.category == selectedCategory }

        // 2. 검색어 필터링
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    /// 인기 공간 목록 (전체 카테고리에서만 표시)
    var popularSpaces: [Space] {
        guard selectedCategory == .all && searchText.isEmpty else {
            return []
        }
        return allSpaces.filter { $0.isPopular }
    }

    /// 인기 공간 섹션 표시 여부
    var shouldShowPopularSection: Bool {
        return selectedCategory == .all && searchText.isEmpty && !popularSpaces.isEmpty
    }
}
