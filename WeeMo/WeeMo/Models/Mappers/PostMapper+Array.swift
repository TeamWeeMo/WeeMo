//
//  PostMapper.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation

// MARK: - PostDTO Array Extensions

/// PostDTO 배열에 대한 공통 변환 메서드
extension Array where Element == PostDTO {
    /// DTO 배열 → Feed 배열 변환
    func toFeeds() -> [Feed] {
        return map { $0.toFeed() }
    }

    /// DTO 배열 → Space 배열 변환
    func toSpaces() -> [Space] {
        return map { $0.toSpace() }
    }

    /// DTO 배열 → Meet 배열 변환
    func toMeets() -> [Meet] {
        return map { $0.toMeet() }
    }

    /// category에 따라 자동으로 변환
    /// - Note: 타입 추론이 필요하므로 반환 타입을 명시해야 함
    /// - Example:
    ///   let feeds: [Feed] = posts.toDomainByCategory()
    ///   let spaces: [Space] = posts.toDomainByCategory()
    func toDomainByCategory<T>() -> [T] {
        return compactMap { post in
            switch post.category.lowercased() {
            case "space":
                return post.toSpace() as? T
            case "meet":
                return post.toMeet() as? T
            case "feed":
                return post.toFeed() as? T
            default:
                return post.toFeed() as? T
            }
        }
    }
}
