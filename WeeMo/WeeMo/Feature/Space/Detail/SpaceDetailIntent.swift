//
//  SpaceDetailIntent.swift
//  WeeMo
//
//  Created by Reimos on 11/17/25.
//

import Foundation

// MARK: - Space Detail Intent

enum SpaceDetailIntent {
    // 화면 진입
    case viewAppeared

    // 날짜 선택
    case dateSelected(Date)

    // 사용자 프로필 로드 완료
    case profileLoaded

    // 예약하기 버튼 탭
    case reservationButtonTapped

    // 예약 확인
    case confirmReservation

    // Alert 닫기
    case dismissAlert
}
