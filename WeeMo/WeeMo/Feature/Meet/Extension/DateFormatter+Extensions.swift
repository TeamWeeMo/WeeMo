//
//  DateFormatter+Extensions.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import Foundation

extension DateFormatter {
    static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd (E) HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    static let simpleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    static let timeOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
}

// MARK: - Date Extensions for Chat

extension Date {
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
