//
//  DateFormatterManager.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/15/25.
//

import Foundation

// MARK: - Date Formatter Manager

/// 날짜 포맷 관리 유틸리티
enum DateFormatterManager {
    /// ISO8601 날짜 포맷터 (서버 응답용)
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// 기본 날짜 포맷터 (yyyy-MM-dd)
    static let standard: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    /// 시간 포함 포맷터 (yyyy-MM-dd HH:mm)
    static let withTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    /// 예약 댓글용 포맷터 (yyyyMMdd)
    static let reservation: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    /// 모임 날짜 포맷터 (M월 d일 (E))
    static let meetDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 (E)"
        return formatter
    }()

    /// 모임 시간 포맷터 (HH:mm)
    static let meetTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    /// 한국어 날짜+시간 포맷터 (M월 d일 a h시)
    static let koreanDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일 a h시"
        return formatter
    }()
}

// MARK: - String Extension

extension String {
    /// ISO8601 문자열을 Date로 변환
    /// - Returns: 변환된 Date 객체 (실패 시 nil)
    func toDate() -> Date? {
        return DateFormatterManager.iso8601.date(from: self)
    }
}

// MARK: - Date Extension

extension Date {
    /// 상대적 시간 문자열 (예: "3시간 전", "방금 전")
    /// - Returns: 한국어 상대 시간 문자열
    func timeAgoString() -> String {
        let now = Date()
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: self,
            to: now
        )

        if let year = components.year, year > 0 {
            return "\(year)년 전"
        } else if let month = components.month, month > 0 {
            return "\(month)개월 전"
        } else if let day = components.day, day > 0 {
            return "\(day)일 전"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)시간 전"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)분 전"
        } else {
            return "방금 전"
        }
    }

    /// ISO8601 문자열로 변환
    func toISO8601String() -> String {
        return DateFormatterManager.iso8601.string(from: self)
    }

    /// 표준 날짜 문자열로 변환 (yyyy-MM-dd)
    func toStandardString() -> String {
        return DateFormatterManager.standard.string(from: self)
    }

    /// 시간 포함 문자열로 변환 (yyyy-MM-dd HH:mm)
    func toStringWithTime() -> String {
        return DateFormatterManager.withTime.string(from: self)
    }

    /// 채팅 시간 표시용 (예: "오후 2:30")
    func chatTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self)
    }

    /// 채팅방 목록에서 사용할 상대적 시간 표시 (예: "방금 전", "5분 전", "어제", "11/15")
    func chatTimeAgoString() -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(self)

        // 1분 미만
        if timeInterval < 60 {
            return "방금 전"
        }

        // 1시간 미만
        if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)분 전"
        }

        // 24시간 미만
        if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)시간 전"
        }

        // 같은 연도
        let calendar = Calendar.current
        if calendar.component(.year, from: self) == calendar.component(.year, from: now) {
            // 어제
            if calendar.isDateInYesterday(self) {
                return "어제"
            }
            // 이번 주
            else if timeInterval < 604800 { // 7일
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                formatter.locale = Locale(identifier: "ko_KR")
                return formatter.string(from: self)
            }
            // 이번 년도
            else {
                let formatter = DateFormatter()
                formatter.dateFormat = "M/d"
                formatter.locale = Locale(identifier: "ko_KR")
                return formatter.string(from: self)
            }
        }

        // 다른 연도
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/M/d"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self)
    }
}
