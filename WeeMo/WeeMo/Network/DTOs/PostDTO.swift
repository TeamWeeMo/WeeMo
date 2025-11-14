//
//  PostDTO.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation

// MARK: - Post DTOs

/// 게시글 DTO
struct PostDTO: Decodable {
    let postId: String
    let category: String
    let title: String
    let price: Int
    let content: String
    let value1: String
    let value2: String
    let value3: String
    let value4: String
    let value5: String
    let value6: String
    let value7: String
    let value8: String
    let value9: String
    let value10: String
    let createdAt: String
    let creator: UserDTO
    let files: [String]
    let likes: [String]
    let likes2: [String]
    let buyers: [String]
    let hashTags: [String]
    let commentCount: Int
    let geolocation: GeolocationDTO
    let distance: Double

    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case category
        case title
        case price
        case content
        case value1, value2, value3, value4, value5
        case value6, value7, value8, value9, value10
        case createdAt
        case creator
        case files
        case likes
        case likes2
        case buyers
        case hashTags
        case commentCount = "comment_count"
        case geolocation
        case distance
    }
}

/// 위치 정보 DTO
struct GeolocationDTO: Decodable {
    let longitude: Double
    let latitude: Double
}

/// 게시글 목록 응답
struct PostListDTO: Decodable {
    let data: [PostDTO]
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}
