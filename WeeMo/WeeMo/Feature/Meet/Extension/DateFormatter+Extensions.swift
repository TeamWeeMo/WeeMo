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
        let timeInterval = abs(now.timeIntervalSince(self))
        let calendar = Calendar.current

        // 디버깅 로그
        print("시간 계산: 메시지=\(self), 현재=\(now), 간격=\(timeInterval)초")

        // 1분 미만
        if timeInterval < 60 {
            return "방금 전"
        }

        // 1시간 미만
        if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)분 전"
        }

        // 오늘인지 확인
        if calendar.isDate(self, inSameDayAs: now) {
            let hours = Int(timeInterval / 3600)
            return "\(hours)시간 전"
        }

        // 어제인지 확인
        if calendar.isDateInYesterday(self) {
            return "어제"
        }

        // 2일 이상 지난 경우
        let daysSince = calendar.dateComponents([.day], from: calendar.startOfDay(for: self), to: calendar.startOfDay(for: now)).day ?? 0

        if daysSince >= 2 {
            // 같은 연도인지 확인
            if calendar.component(.year, from: self) == calendar.component(.year, from: now) {
                let formatter = DateFormatter()
                formatter.dateFormat = "M/d"
                formatter.locale = Locale(identifier: "ko_KR")
                return formatter.string(from: self)
            } else {
                // 다른 연도
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy/M/d"
                formatter.locale = Locale(identifier: "ko_KR")
                return formatter.string(from: self)
            }
        }

        // 1일 전 (어제가 아닌 경우 - 요일로 표시)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self)
    }
}
