//
//  ReservationFormatter.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/25/25.
//

import Foundation

// MARK: - Reservation Formatter

/// 예약 정보를 포맷팅하는 유틸리티
struct ReservationFormatter {

    // MARK: - Date Formatting

    /// 날짜를 한글 형식으로 포맷팅 (예: 2025년 11월 17일)
    /// - Parameter date: 포맷팅할 날짜
    /// - Returns: 한글 형식 날짜 문자열
    static func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: date)
    }

    /// 날짜를 짧은 형식으로 포맷팅 (예: 11월 17일)
    /// - Parameter date: 포맷팅할 날짜
    /// - Returns: 짧은 형식 날짜 문자열
    static func formattedShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MM월 dd일"
        return formatter.string(from: date)
    }

    // MARK: - Time Formatting

    /// 시간대를 포맷팅 (예: 14:00 - 15:00)
    /// - Parameters:
    ///   - startHour: 시작 시간 (0-23)
    ///   - endHour: 종료 시간 (1-24)
    /// - Returns: 시간대 문자열
    static func formattedTimeSlot(startHour: Int, endHour: Int) -> String {
        return String(format: "%02d:00 - %02d:00", startHour, endHour)
    }

    /// 시간 범위를 계산 (예: 3시간)
    /// - Parameters:
    ///   - startHour: 시작 시간
    ///   - endHour: 종료 시간
    /// - Returns: 시간 차이
    static func calculateHours(startHour: Int, endHour: Int) -> Int {
        return max(0, endHour - startHour)
    }

    // MARK: - Combined Formatting

    /// 날짜와 시간을 결합하여 포맷팅 (예: 2025년 11월 17일 14:00 - 15:00)
    /// - Parameters:
    ///   - date: 날짜
    ///   - startHour: 시작 시간
    ///   - endHour: 종료 시간
    /// - Returns: 날짜 + 시간 문자열
    static func formattedDateTime(date: Date, startHour: Int, endHour: Int) -> String {
        let dateStr = formattedDate(date)
        let timeStr = formattedTimeSlot(startHour: startHour, endHour: endHour)
        return "\(dateStr) \(timeStr)"
    }

    /// 날짜와 시간을 짧은 형식으로 결합 (예: 11/17 14:00-15:00)
    /// - Parameters:
    ///   - date: 날짜
    ///   - startHour: 시작 시간
    ///   - endHour: 종료 시간
    /// - Returns: 짧은 형식 날짜 + 시간 문자열
    static func formattedShortDateTime(date: Date, startHour: Int, endHour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        let dateStr = formatter.string(from: date)
        let timeStr = String(format: "%02d:00-%02d:00", startHour, endHour)
        return "\(dateStr) \(timeStr)"
    }

    // MARK: - ISO Format Parsing

    /// ISO 형식의 예약 정보를 파싱 (형식: #yyyyMMddHHmm, totalHours)
    /// - Parameter content: ISO 형식 문자열 (예: "#202511240100, 3")
    /// - Returns: (날짜, 시작시간, 총시간) 또는 nil
    static func parseReservationISO(_ content: String) -> (date: Date, startHour: Int, totalHours: Int)? {
        // "#202511240100, 3" 형식을 파싱
        let components = content.components(separatedBy: ", ")
        guard components.count == 2,
              let isoString = components.first?.trimmingCharacters(in: CharacterSet(charactersIn: "#")),
              let totalHours = Int(components[1]),
              isoString.count >= 12 else {
            return nil
        }

        // yyyyMMddHHmm 파싱
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmm"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = TimeZone.current

        guard let date = dateFormatter.date(from: isoString) else {
            return nil
        }

        // 시작 시간 추출 (HH 부분)
        let startIndex = isoString.index(isoString.startIndex, offsetBy: 8)
        let endIndex = isoString.index(startIndex, offsetBy: 2)
        let hourString = String(isoString[startIndex..<endIndex])

        guard let startHour = Int(hourString) else {
            return nil
        }

        return (date, startHour, totalHours)
    }

    /// ISO 형식의 예약 정보를 생성 (형식: #yyyyMMddHHmm, totalHours)
    /// - Parameters:
    ///   - date: 날짜
    ///   - startHour: 시작 시간
    ///   - totalHours: 총 시간
    /// - Returns: ISO 형식 문자열
    static func createReservationISO(date: Date, startHour: Int, totalHours: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: date)
        let startHourString = String(format: "%02d00", startHour)
        return "#\(dateString)\(startHourString), \(totalHours)"
    }
}
