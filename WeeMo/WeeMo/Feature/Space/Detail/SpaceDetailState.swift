//
//  SpaceDetailState.swift
//  WeeMo
//
//  Created by Reimos on 11/17/25.
//

import Foundation

// MARK: - Space Detail State

struct SpaceDetailState {
    // 사용자 정보
    var userProfileImage: String? = nil
    var userNickname: String = ""

    // 날짜 및 시간 선택
    var selectedDate: Date? = nil
    var startHour: Int? = nil // 시작 시간 (0~23)
    var endHour: Int? = nil   // 종료 시간 (1~24)

    // 가격 정보
    var pricePerHour: Int = 0

    // 로딩 및 에러
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // 예약 정보 표시 여부
    var showReservationInfo: Bool = false

    // 좋아요(예약) 상태
    var isLiked: Bool = false
    var isLikeLoading: Bool = false

    // 예약된(블락된) 시간 - 날짜별로 관리
    var blockedHoursByDate: [Date: Set<Int>] = [:]

    // MARK: - Computed Properties

    /// 현재 선택된 날짜의 블락된 시간
    var currentBlockedHours: Set<Int> {
        guard let date = selectedDate else { return [] }
        let calendar = Calendar.current
        let dateOnly = calendar.startOfDay(for: date)
        return blockedHoursByDate[dateOnly] ?? []
    }

    /// 선택된 시간 (시간 단위)
    var selectedHours: Int {
        guard let start = startHour, let end = endHour else { return 0 }
        return max(0, end - start)
    }

    /// 예약 가능 여부 (날짜와 시간이 모두 선택되었는지)
    var canReserve: Bool {
        selectedDate != nil && startHour != nil && endHour != nil
    }

    /// 예약 정보를 보여줄 수 있는지 (예약 정보가 표시 중이고 예약 가능한 상태)
    var shouldShowReservationInfo: Bool {
        showReservationInfo && canReserve
    }

    /// 선택된 날짜 포맷팅 (예: 2025년 11월 17일)
    var formattedDate: String {
        guard let date = selectedDate else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: date)
    }

    /// 선택된 시간대 포맷팅 (예: 14:00 - 15:00)
    var formattedTimeSlot: String {
        guard let start = startHour, let end = endHour else { return "" }
        return String(format: "%02d:00 - %02d:00", start, end)
    }

    /// 총 가격 (선택한 시간 기준)
    var totalPrice: String {
        guard selectedHours > 0 else { return "0원" }
        let total = pricePerHour * selectedHours
        return "\(total.formattedWithComma())원"
    }
}

// MARK: - Int Extension for Price Formatting

private extension Int {
    func formattedWithComma() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
