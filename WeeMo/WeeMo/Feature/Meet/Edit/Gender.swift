//
//  Gender.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/24/25.
//

import Foundation

// MARK: - Gender Enum

/// 모임 성별 제한
enum Gender: Int, CaseIterable, Codable {
    case anyone = 0     // 누구나
    case maleOnly = 1   // 남성만
    case femaleOnly = 2 // 여성만

    // MARK: - Display Text

    var displayText: String {
        switch self {
        case .anyone: return "누구나"
        case .maleOnly: return "남성만"
        case .femaleOnly: return "여성만"
        }
    }

    // MARK: - Initializer

    /// 문자열에서 Gender로 변환
    init(from string: String) {
        switch string {
        case "남성만", "1":
            self = .maleOnly
        case "여성만", "2":
            self = .femaleOnly
        default:
            self = .anyone
        }
    }

    /// Int 값에서 Gender로 변환 (기본값: anyone)
    init(rawValue: Int) {
        switch rawValue {
        case 1: self = .maleOnly
        case 2: self = .femaleOnly
        default: self = .anyone
        }
    }
}
