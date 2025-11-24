//
//  MeetMapState.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/19/25.
//

import Foundation
import CoreLocation

// MARK: - MeetMap State

struct MeetMapState {
    // 데이터
    var meets: [Meet] = []
    var filteredMeets: [Meet] = []

    // 로딩 상태
    var isLoading: Bool = false

    // 에러
    var errorMessage: String? = nil

    // UI 상태
    var showingSearch: Bool = false
    var searchText: String = ""
    var hasSearched: Bool = false // 검색 버튼을 눌렀는지 여부
    var lastSearchedQuery: String = "" // 마지막 검색어 (중복 검색 방지)

    // Alert
    var showSearchAlert: Bool = false
    var searchAlertMessage: String = ""

    // 지도 상태
    var cameraPosition: CLLocationCoordinate2D = CLLocationCoordinate2D(
        latitude: 37.5665,
        longitude: 126.9780
    )
    var currentZoom: Double = 13.0 // 현재 줌 레벨
    var userLocation: CLLocationCoordinate2D? = nil
    var visibleMeets: [Meet] = [] // 현재 지도 범위 내 모임들 (API로부터)
    var lastAPICallLocation: CLLocationCoordinate2D? = nil // 마지막 API 호출 위치
    var mapVisibleBounds: (minLat: Double, maxLat: Double, minLng: Double, maxLng: Double)? = nil // 현재 지도 영역

    // 네비게이션
    var selectedMeet: Meet? = nil

    // MARK: - Computed Properties

    /// 빈 상태 여부
    var isEmpty: Bool {
        meets.isEmpty && !isLoading
    }

    /// 검색 결과가 비어있는지 (검색 버튼을 눌렀고, 로딩이 완료된 후에만 체크)
    var isSearchEmpty: Bool {
        hasSearched && filteredMeets.isEmpty && searchText.count >= 2 && !isLoading
    }

    /// 현재 지도 영역 내에 보이는 모임들 (하단 리스트용)
    var meetsInCurrentView: [Meet] {
        guard let bounds = mapVisibleBounds else { return visibleMeets }

        return visibleMeets.filter { meet in
            meet.latitude >= bounds.minLat &&
            meet.latitude <= bounds.maxLat &&
            meet.longitude >= bounds.minLng &&
            meet.longitude <= bounds.maxLng
        }
    }
}
