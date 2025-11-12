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
