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
    let address: String
    let imageURLs: [String]
    let rating: Double
    let maxRating: Double = 5.0
    let pricePerHour: Int
    let category: SpaceCategory
    let isPopular: Bool
    let amenities: [SpaceAmenity]
    let hasParking: Bool
    let description: String
    let latitude: Double?
    let longitude: Double?

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
        return "\(formattedRating) / \(String(format: "%.1f", maxRating))"
    }

    var amenityTags: [String] {
        return amenities.map { "#\($0.rawValue)" }
    }
}
