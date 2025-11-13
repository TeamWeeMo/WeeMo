//
//  PostRouter.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/13/25.
//

import Foundation
import Alamofire

// MARK: - Post Router

enum PostRouter: APIRouter {
    // 파일 업로드
    case uploadFiles(images: [Data])

    // 게시글 CRUD
    case createPost(title: String, content: String, category: PostCategory, files: [String], additionalFields: [String: String]?)
    case fetchPosts(next: String?, limit: Int?, category: PostCategory?)
    case fetchPost(postId: String)
    case updatePost(postId: String, title: String?, content: String?, files: [String]?)
    case deletePost(postId: String)

    // 좋아요
    case likePost(postId: String)
    case likePost2(postId: String)
    case fetchMyLikedPosts(next: String?, limit: Int?, category: PostCategory?)
    case fetchMyLikedPosts2(next: String?, limit: Int?, category: PostCategory?)

    // 조회
    case fetchUserPosts(userId: String, next: String?, limit: Int?, category: PostCategory?)
    case searchByHashtag(hashtag: String, next: String?, limit: Int?, category: PostCategory?)
    case fetchFollowingFeed(next: String?, limit: Int?, category: PostCategory?)
    case searchByLocation(category: PostCategory?, longitude: Double, latitude: Double, maxDistance: Int?, orderBy: String?, sortBy: String?)
    case searchByTitle(title: String, category: PostCategory?)

    // MARK: - APIRouter Implementation

    var method: HTTPMethod {
        switch self {
        case .uploadFiles, .createPost, .likePost, .likePost2:
            return .post
        case .fetchPosts, .fetchPost, .fetchMyLikedPosts, .fetchMyLikedPosts2, .fetchUserPosts, .searchByHashtag, .fetchFollowingFeed, .searchByLocation, .searchByTitle:
            return .get
        case .updatePost:
            return .put
        case .deletePost:
            return .delete
        }
    }

    var path: String {
        let version = NetworkConstants.apiVersion
        switch self {
        case .uploadFiles:
            return "\(version)/posts/files"
        case .createPost:
            return "\(version)/posts"
        case .fetchPosts:
            return "\(version)/posts"
        case .fetchPost(let postId):
            return "\(version)/posts/\(postId)"
        case .updatePost(let postId, _, _, _):
            return "\(version)/posts/\(postId)"
        case .deletePost(let postId):
            return "\(version)/posts/\(postId)"
        case .likePost(let postId):
            return "\(version)/posts/\(postId)/like"
        case .likePost2(let postId):
            return "\(version)/posts/\(postId)/like-2"
        case .fetchMyLikedPosts:
            return "\(version)/posts/likes/me"
        case .fetchMyLikedPosts2:
            return "\(version)/posts/likes-2/me"
        case .fetchUserPosts(let userId, _, _, _):
            return "\(version)/posts/users/\(userId)"
        case .searchByHashtag:
            return "\(version)/posts/hashtags"
        case .fetchFollowingFeed:
            return "\(version)/posts/feed"
        case .searchByLocation:
            return "\(version)/posts/geolocation"
        case .searchByTitle:
            return "\(version)/posts/search"
        }
    }

    var parameters: Parameters? {
        switch self {
        case .uploadFiles:
            return nil

        case .createPost(let title, let content, let category, let files, let additionalFields):
            var params: Parameters = [
                "title": title,
                "content": content,
                "category": category.rawValue,
                "files": files
            ]
            // 추가 필드 병합 (value1~10)
            if let additional = additionalFields {
                params.merge(additional) { _, new in new }
            }
            return params

        case .fetchPosts(let next, let limit, let category):
            var params: Parameters = [:]
            if let next = next { params["next"] = next }
            if let limit = limit { params["limit"] = limit }
            if let category = category { params["category"] = category.rawValue }
            return params.isEmpty ? nil : params

        case .fetchPost:
            return nil

        case .updatePost(_, let title, let content, let files):
            var params: Parameters = [:]
            if let title = title { params["title"] = title }
            if let content = content { params["content"] = content }
            if let files = files { params["files"] = files }
            return params.isEmpty ? nil : params

        case .deletePost, .likePost, .likePost2:
            return nil

        case .fetchMyLikedPosts(let next, let limit, let category),
             .fetchMyLikedPosts2(let next, let limit, let category):
            var params: Parameters = [:]
            if let next = next { params["next"] = next }
            if let limit = limit { params["limit"] = limit }
            if let category = category { params["category"] = category.rawValue }
            return params.isEmpty ? nil : params

        case .fetchUserPosts(_, let next, let limit, let category):
            var params: Parameters = [:]
            if let next = next { params["next"] = next }
            if let limit = limit { params["limit"] = limit }
            if let category = category { params["category"] = category.rawValue }
            return params.isEmpty ? nil : params

        case .searchByHashtag(let hashtag, let next, let limit, let category):
            var params: Parameters = ["hashTag": hashtag]
            if let next = next { params["next"] = next }
            if let limit = limit { params["limit"] = limit }
            if let category = category { params["category"] = category.rawValue }
            return params

        case .fetchFollowingFeed(let next, let limit, let category):
            var params: Parameters = [:]
            if let next = next { params["next"] = next }
            if let limit = limit { params["limit"] = limit }
            if let category = category { params["category"] = category.rawValue }
            return params.isEmpty ? nil : params

        case .searchByLocation(let category, let longitude, let latitude, let maxDistance, let orderBy, let sortBy):
            var params: Parameters = [
                "longitude": longitude,
                "latitude": latitude
            ]
            if let category = category { params["category"] = category.rawValue }
            if let maxDistance = maxDistance { params["maxDistance"] = maxDistance }
            if let orderBy = orderBy { params["order_by"] = orderBy }
            if let sortBy = sortBy { params["sort_by"] = sortBy }
            return params

        case .searchByTitle(let title, let category):
            var params: Parameters = ["title": title]
            if let category = category { params["category"] = category.rawValue }
            return params
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .uploadFiles:
            return URLEncoding.default
        default:
            return method == .get ? URLEncoding.default : JSONEncoding.default
        }
    }
}
