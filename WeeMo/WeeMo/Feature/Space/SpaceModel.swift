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
