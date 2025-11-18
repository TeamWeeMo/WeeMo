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
        // value2: 평점
        // value3: 인기 공간 여부 ("true" or "false")
        // value4: 편의시설 (쉼표로 구분된 문자열)
        // value5: 주차 가능 여부 ("true" or "false")

        let amenitiesString = value4 ?? ""
        let amenities = parseAmenities(from: amenitiesString)

        return Space(
            id: postId,
            title: title,
            address: value1 ?? "주소 없음",
            imageURLs: files,
            rating: Double(value2 ?? "0.0") ?? 0.0,
            pricePerHour: price ?? 0,
            category: parseSpaceCategory(from: category),
            isPopular: value3 == "true",
            amenities: amenities,
            latitude: geolocation.latitude,
            longitude: geolocation.longitude
            hasParking: value3 == "true",
            description: content,
            hashTags: hashTags  // 서버에서 받은 해시태그
        )
    }

    // MARK: - Private Helpers

    private func parseSpaceCategory(from categoryString: String?) -> SpaceCategory {
        guard let categoryString = categoryString else { return .cafe }

        switch categoryString.lowercased() {
        case "cafe", "카페":
            return .cafe
        case "studyroom", "study", "스터디룸":
            return .studyRoom
        case "meetingroom", "meeting", "회의실":
            return .meetingRoom
        case "party", "파티":
            return .party
        default:
            return .cafe
        }
    }

    private func parseAmenities(from amenitiesString: String) -> [SpaceAmenity] {
        // 서버에서 받은 amenities 문자열 파싱
        // 예: "WiFi,콘센트,조용함" 형태로 가정
        let amenityNames = amenitiesString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }

        return amenityNames.compactMap { name in
            switch name.lowercased() {
            case "조용함", "quiet":
                return .quiet
            case "wifi":
                return .wifi
            case "콘센트", "power":
                return .power
            case "프로젝터", "projector":
                return .projector
            case "화이트보드", "whiteboard":
                return .whiteboard
            case "주방시설", "kitchen":
                return .kitchen
            case "주차", "parking":
                return .parking
            case "프린터", "printer":
                return .printer
            default:
                return nil
            }
        }
    }
}
