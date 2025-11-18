//
//  SpaceModel.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import Foundation

enum SpaceCategory: String, CaseIterable {
    case all = "전체"
    case cafe = "카페"
    case studyRoom = "스터디룸"
    case meetingRoom = "회의실"
    case party = "파티"
}

enum SpaceAmenity: String {
    case quiet = "조용함"
    case wifi = "WiFi"
    case power = "콘센트"
    case projector = "프로젝터"
    case whiteboard = "화이트보드"
    case kitchen = "주방시설"
    case parking = "주차"
    case printer = "프린터"
}

// MARK: - Mock Data
//extension Space {
//    static let mockSpaces: [Space] = [
//        Space(
//            id: "1",
//            title: "모던 카페 라운지",
//            address: "서울 강남구 테헤란로 123",
//            imageURLs: ["cafe1", "cafe2", "cafe3"],
//            rating: 4.8,
//            pricePerHour: 15000,
//            category: .cafe,
//            isPopular: true,
//            amenities: [.quiet, .wifi, .power],
//            hasParking: true,
//            description: "조용하고 아늑한 분위기의 카페입니다. 스터디나 작업하기 좋은 공간으로, 고속 WiFi와 충분한 콘센트를 제공합니다.",
//            latitude: 37.4979,
//            longitude: 127.0276
//        ),
//        Space(
//            id: "2",
//            title: "코워킹 스페이스",
//            address: "서울 강남구 역삼동 456",
//            imageURLs: ["coworking1", "coworking2", "coworking3"],
//            rating: 4.9,
//            pricePerHour: 20000,
//            category: .studyRoom,
//            isPopular: true,
//            amenities: [.wifi, .power, .printer, .whiteboard],
//            hasParking: true,
//            description: "프리미엄 코워킹 스페이스입니다. 개인 작업부터 팀 프로젝트까지 가능하며, 프린터와 화이트보드를 무료로 이용하실 수 있습니다.",
//            latitude: 37.5009,
//            longitude: 127.0372
//        ),
//        Space(
//            id: "3",
//            title: "프라이빗 미팅룸",
//            address: "서울 서초구 서초동 789",
//            imageURLs: ["meeting1", "meeting2"],
//            rating: 4.7,
//            pricePerHour: 25000,
//            category: .meetingRoom,
//            isPopular: false,
//            amenities: [.projector, .whiteboard, .wifi],
//            hasParking: false,
//            description: "소규모 회의에 최적화된 프라이빗 룸입니다. 빔프로젝터와 화이트보드가 구비되어 있어 프레젠테이션이 가능합니다.",
//            latitude: 37.4837,
//            longitude: 127.0324
//        ),
//        Space(
//            id: "4",
//            title: "파티룸 플러스",
//            address: "서울 마포구 홍대입구 234",
//            imageURLs: ["party1", "party2", "party3"],
//            rating: 4.6,
//            pricePerHour: 30000,
//            category: .party,
//            isPopular: false,
//            amenities: [.kitchen, .wifi, .projector],
//            hasParking: true,
//            description: "생일파티, 모임 등 다양한 이벤트를 위한 공간입니다. 주방시설이 완비되어 있어 간단한 요리도 가능합니다.",
//            latitude: 37.5563,
//            longitude: 126.9235
//        ),
//        Space(
//            id: "5",
//            title: "조용한 스터디카페",
//            address: "서울 송파구 잠실동 567",
//            imageURLs: ["study1", "study2"],
//            rating: 4.5,
//            pricePerHour: 10000,
//            category: .studyRoom,
//            isPopular: false,
//            amenities: [.quiet, .wifi, .power],
//            hasParking: false,
//            description: "집중력이 필요한 학습과 업무를 위한 조용한 공간입니다. 쾌적한 환경에서 편안하게 공부하실 수 있습니다.",
//            latitude: 37.5125,
//            longitude: 127.1002
//        )
//    ]
//}
//
