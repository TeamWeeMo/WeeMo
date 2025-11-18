//
//  SpaceListIntent.swift
//  WeeMo
//
//  Created by Reimos on 11/15/25
//

import Foundation

// MARK: - Space List Intent

/// SpaceListView에서 발생하는 모든 사용자 액션 정의
enum SpaceListIntent {
    // 화면 생명주기
    case viewAppeared

    // 검색
    case searchTextChanged(String)

    // 카테고리 필터링
    case categoryChanged(SpaceCategory)

    // 공간 선택
    case spaceSelected(Space)

    // 새로고침
    case refresh
}
