//
//  MeetListState.swift
//  WeeMo
//
//  Created by 차지용 on 11/16/25.
//

import Foundation

struct MeetListState {
    var meets: [Meet] = []
    var allMeets: [Meet] = [] // 원본 데이터 보관
    var filteredMeets: [Meet] = [] // 검색 결과 보관
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var searchQuery: String = ""
    var currentSortOption: SortOption = .registrationDate

    // 페이지네이션
    var nextCursor: String? = nil
    var hasMoreData: Bool = true
    var isLoadingMore: Bool = false
}
