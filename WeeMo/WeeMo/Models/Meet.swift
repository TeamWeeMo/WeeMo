//
//  Meet.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/12/25.
//

import Foundation

struct Meet: Identifiable, Equatable, Hashable {
    let id: String // post_id
    let title: String // 모임 제목
    let content: String // 모임 소개
    let fileURLs: [String] // 파일 URL 배열
    let creator: User // 게시글 작성 유저
    let createdAt: Date

    // MARK: - 모집 정보

    let capacity: Int // 모집 인원 (value1)
    let participants: Int // 참여인원 (buyer.count)
    let gender: Gender // 성별 제한 (value2)
    let recruitmentStartDate: Date // 모집 시작일
    let recruitmentEndDate: Date // 모집 종료일

    // MARK: - 모임 시간 정보 (value3: ISO 형식 "yyyyMMddHHmm,totalHours")

    let reservationInfo: String // 예약 정보 ISO 형식 (예: "202511211400,3")

    // MARK: - Computed Properties (예약 정보 파싱)

    /// 예약 정보를 파싱하여 시작 날짜/시간 반환
    var meetingStartDate: Date {
        guard let parsed = ReservationFormatter.parseReservationISO("#\(reservationInfo)") else {
            return Date() // 파싱 실패 시 현재 시간 반환
        }
        return parsed.date
    }

    /// 예약 정보를 파싱하여 종료 날짜/시간 반환
    var meetingEndDate: Date {
        guard let parsed = ReservationFormatter.parseReservationISO("#\(reservationInfo)") else {
            return Date()
        }
        return Calendar.current.date(byAdding: .hour, value: parsed.totalHours, to: parsed.date) ?? Date()
    }

    /// 총 이용 시간 (파싱)
    var totalHours: Int {
        guard let parsed = ReservationFormatter.parseReservationISO("#\(reservationInfo)") else {
            return 0
        }
        return parsed.totalHours
    }

    // MARK: - 공간 정보 (value4)

    let spaceId: String? // 선택된 공간 Id
    let spaceName: String // 공간 이름
    let address: String // 공간 주소
    let spaceImageURL: String? // 공간 대표 이미지 URL
    let latitude: Double
    let longitude: Double

    // MARK: - 참가비

    let pricePerPerson: Int // 참가비 (pricePerHour * totalHours / capacity)

    // MARK: - 기타

    let likes: [String] // 좋아요한 사용자 ID 배열
    let distance: Double? // 거리 (위치 기반 검색 시)

    // MARK: - Computed Properties

    /// 현재 사용자가 좋아요했는지 여부
    var isLiked: Bool {
        let currentUserId = TokenManager.shared.userId ?? ""
        return likes.contains(currentUserId)
    }

    /// 좋아요 개수
    var likeCount: Int {
        likes.count
    }

    /// 모집 완료 여부 (인원이 다 찬 경우)
    var isFullyBooked: Bool {
        return participants >= capacity
    }

    /// 모집 종료 여부 (시간까지 고려)
    var isRecruitmentEnded: Bool {
        return Date() > recruitmentEndDate
    }

    /// 모집 중 여부
    var isRecruiting: Bool {
        let now = Date()
        return now >= recruitmentStartDate && now <= recruitmentEndDate && !isFullyBooked
    }

    /// 모집 마감까지 남은 일수
    var daysUntilDeadline: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: recruitmentEndDate).day ?? 0
    }

    /// D-Day 문자열
    var dDayText: String {
        // 모집 완료 (인원 마감)
        if isFullyBooked {
            return "모집 완료"
        }

        // 모집 시간 종료
        if isRecruitmentEnded {
            return "마감"
        }

        // 남은 일수 계산
        let days = daysUntilDeadline
        if days < 0 {
            return "마감"
        } else if days == 0 {
            return "오늘 마감"
        } else {
            return "\(days)일 전"
        }
    }

    /// 모임 시간 문자열 (예: "14:00 - 16:00")
    var meetingTimeText: String {
        let startTime = DateFormatterManager.meetTime.string(from: meetingStartDate)
        let endTime = DateFormatterManager.meetTime.string(from: meetingEndDate)
        return "\(startTime) - \(endTime)"
    }

    /// 모임 날짜 문자열 (예: "11월 21일 (금)")
    var meetingDateText: String {
        DateFormatterManager.meetDate.string(from: meetingStartDate)
    }

    /// 참가비 문자열
    var priceText: String {
        if pricePerPerson == 0 {
            return "무료"
        } else {
            return "\(pricePerPerson.formatted())원"
        }
    }

    /// 공간 예약 시간 문자열 (예: "14:00 - 16:00 (2시간)")
    var reservationTimeText: String {
        let startTime = DateFormatterManager.meetTime.string(from: meetingStartDate)
        let endTime = DateFormatterManager.meetTime.string(from: meetingEndDate)
        return "\(startTime) - \(endTime) (\(totalHours)시간)"
    }

    /// 공간 예약 날짜+시간 전체 문자열 (예: "11월 21일 (금) 14:00-16:00")
    var fullReservationText: String {
        let dateStr = DateFormatterManager.meetDate.string(from: meetingStartDate)
        let startTime = DateFormatterManager.meetTime.string(from: meetingStartDate)
        let endTime = DateFormatterManager.meetTime.string(from: meetingEndDate)
        return "\(dateStr) \(startTime)-\(endTime)"
    }

    /// 공간 예약 시간 (한국어 형식) (예: "11월 21일 오후 2시 ~ 오후 7시")
    var spaceReservationScheduleText: String {
        let startStr = DateFormatterManager.koreanDateTime.string(from: meetingStartDate)
        let endStr = DateFormatterManager.koreanDateTime.string(from: meetingEndDate)
        return "\(startStr) ~ \(endStr)"
    }

    /// 모집 일정 (한국어 형식) (예: "11월 21일 오후 12시 ~ 오후 2시" 또는 "11월 20일 오후 1시 ~ 11월 21일 오후 2시")
    var recruitmentScheduleText: String {
        let calendar = Calendar.current
        let isSameDay = calendar.isDate(recruitmentStartDate, inSameDayAs: recruitmentEndDate)

        if isSameDay {
            // 같은 날: "11월 21일 오후 12시 ~ 오후 2시"
            let dateStr = DateFormatterManager.meetDate.string(from: recruitmentStartDate)
            let startTime = DateFormatterManager.koreanTime.string(from: recruitmentStartDate)
            let endTime = DateFormatterManager.koreanTime.string(from: recruitmentEndDate)
            return "\(dateStr) \(startTime) ~ \(endTime)"
        } else {
            // 다른 날: "11월 28일 오후 6시 ~ 12월 5일 오후 6시"
            let startDate = DateFormatterManager.koreanDateOnly.string(from: recruitmentStartDate)
            let startTime = DateFormatterManager.koreanTime.string(from: recruitmentStartDate)
            let endDate = DateFormatterManager.koreanDateOnly.string(from: recruitmentEndDate)
            let endTime = DateFormatterManager.koreanTime.string(from: recruitmentEndDate)

            return "\(startDate) \(startTime) ~ \(endDate) \(endTime)"
        }
    }

    /// 이미지 파일만 필터링 (동영상 제외)
    var imageFileURLs: [String] {
        fileURLs.filter { urlString in
            let imageExtensions = ["jpg", "jpeg", "png", "heic", "heif", "webp", "gif"]
            let lowercased = urlString.lowercased()
            return imageExtensions.contains { lowercased.hasSuffix(".\($0)") }
        }
    }

    /// 첫 번째 이미지 파일 URL (동영상 제외)
    var firstImageURL: String? {
        imageFileURLs.first
    }
}
