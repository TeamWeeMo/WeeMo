//
//  MeetMapIntent.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/19/25.
//

import Foundation
import CoreLocation

// MARK: - MeetMap Intent

enum MeetMapIntent {
    // 라이프사이클
    case onAppear

    // 검색
    case openSearch
    case closeSearch
    case updateSearchText(String)
    case searchMeets(query: String)
    case clearSearch
    case dismissSearchAlert

    // 네비게이션
    case selectMeet(Meet)
    case selectMeetFromSearch(Meet)
    case clearSelectedMeet

    // 지도 이동
    case moveToCurrentLocation
    case moveToLocation(latitude: Double, longitude: Double)

    // 위치 업데이트
    case updateUserLocation(CLLocationCoordinate2D)

    // 지도 영역 변경 (위치 기반 API 재요청)
    case mapRegionChanged(center: CLLocationCoordinate2D, zoom: Double)

    // 지도 가시 영역 업데이트 (마커 필터링용)
    case updateVisibleBounds(minLat: Double, maxLat: Double, minLng: Double, maxLng: Double)
}
