//
//  Space.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/12/25.
//

import Foundation

struct Space: Identifiable, Hashable {
    let id: String
    let title: String
    let address: String // 주소
    let roadAddress: String? // 도로명 주소
    let category: SpaceCategory // 카테고리
    let imageURLs: [String]
    let rating: Double     // 평점
    let pricePerHour: Int // 시간당 가격
    let isPopular: Bool  // 인기공간
    let hasParking: Bool // 주차
    let hasBathRoom: Bool // 화장실
    let maxPeople: Int // 최대인원
    let description: String
    let latitude: Double
    let longitude: Double
    let hashTags: [String]  // 서버에서 받은 해시태그
    let creatorId: String  // 작성자 ID

    // Hashable 구현
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Space, rhs: Space) -> Bool {
        lhs.id == rhs.id
    }

    var imageURL: String {
        return imageURLs.first ?? ""
    }

    var formattedPrice: String {
        return "\(pricePerHour.formatted())원/시간"
    }

    var formattedRating: String {
        return String(format: "%.1f", rating)
    }

    var formattedDetailRating: String {
        return "\(formattedRating) / \(String(format: "%.1f", 5.0))"
    }

}
