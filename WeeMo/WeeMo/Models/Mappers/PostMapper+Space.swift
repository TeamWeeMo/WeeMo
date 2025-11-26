//
//  PostMapper.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation

// MARK: - Post Mapper

extension PostDTO {

    /// DTO → Domain Model 변환 (Space)
    func toSpace() -> Space {
        // value1: 주소
        // value2: 카테고리
        // value3: 평점
        // value4: 시간당 가격
        // value5: 인기 공간 여부 ("true" or "false")
        // value6: 주차 ("true" or "false")
        // value7: 화장실 여부 ("true" or "false")
        // value8: 최대인원 ("6")
        // value9: 도로명 주소 (상세 주소)

        return Space(
            id: postId,
            title: title,
            address: value1 ?? "주소 없음",
            roadAddress: value9, // 도로명 주소
            category: parseSpaceCategory(from: value2),
            imageURLs: files,
            rating: Double(value3 ?? "0.0") ?? 0.0,
            pricePerHour: Int(value4 ?? "0") ?? 0,
            isPopular: value5 == "true",
            hasParking: value6 == "true",
            hasBathRoom: value7 == "true",
            maxPeople: Int(value8 ?? "0") ?? 0,
            description: content,
            latitude: geolocation.latitude,
            longitude: geolocation.longitude,
            hashTags: hashTags  // 서버에서 받은 해시태그
        )

    }

    // MARK: - Private Helpers

    private func parseSpaceCategory(from categoryString: String?) -> SpaceCategory {

        switch categoryString {
        case "파티룸":
            return .party
        case "스터디룸":
            return .studyRoom
        case "스튜디오":
            return .studio
        case "연습실":
            return .practice
        case "회의실":
            return .meetingRoom
        case "카페":
            return .cafe
        default:
            return .party
        }
    }
}
