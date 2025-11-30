//
//  MeetExtensions.swift
//  WeeMo
//
//  Meet 관련 확장 (뷰 헬퍼, 유틸리티)
//

import SwiftUI

// MARK: - D-Day Color Helper

extension View {
    /// D-Day 배경색을 결정하는 헬퍼 함수
    /// - Parameter meet: Meet 객체
    /// - Returns: 조건에 따른 배경색
    func dDayBackgroundColor(for meet: Meet) -> Color {
        if meet.isFullyBooked {
            return .blue // 모집 완료 (인원 마감)
        } else if meet.isRecruitmentEnded {
            return .black // 모집 시간 종료
        } else if meet.daysUntilDeadline == 0 {
            return .red // 오늘 마감
        } else {
            return .wmMain // 기본
        }
    }
}
