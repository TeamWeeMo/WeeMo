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
}
