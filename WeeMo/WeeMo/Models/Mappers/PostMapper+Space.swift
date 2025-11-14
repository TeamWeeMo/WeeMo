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
        // value1~value10을 Space 필드에 매핑
        // 서버 스펙에 맞춰 매핑 필요 (임시 매핑)
        let amenitiesString = value1
        let amenities = parseAmenities(from: amenitiesString)

        return Space(
            id: postId,
            title: title,
            address: value2,
            imageURLs: files,
            rating: Double(value3) ?? 0.0,
            pricePerHour: price,
            category: parseSpaceCategory(from: category),
            isPopular: value4 == "true",
            amenities: amenities,
            hasParking: value5 == "true",
            description: content
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
