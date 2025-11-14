//
//  PostMapper.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation

// MARK: - Post Mapper

extension PostDTO {

    /// DTO → Domain Model 변환 (Meet)
    func toMeet() -> Meet {
        // value1~value10을 Meet 필드에 매핑
        // 서버 스펙에 맞춰 매핑 필요 (임시 매핑)
        return Meet(
            title: title,
            date: value1,
            location: value2,
            address: value3,
            price: "\(price)원",
            participants: value4,
            imageName: files.first ?? "",
            daysLeft: value5
        )
    }

}
