//
//  PostService.swift
//  WeeMo
//
//  Created by Lee on 11/17/25.
//

import Foundation

// MARK: - Post Service Protocol

protocol PostServicing {
    /// 특정 유저의 게시글 조회
    func fetchUserPosts(userId: String, next: String?, limit: Int?, category: PostCategory?) async throws -> PostListDTO

    /// 내가 좋아요한 게시글 조회
    func fetchMyLikedPosts(next: String?, limit: Int?, category: PostCategory?) async throws -> PostListDTO

    /// 게시글 상세 조회
    func fetchPost(postId: String) async throws -> PostDTO

    /// 게시글 좋아요
    func likePost(postId: String) async throws -> LikeStatusDTO
}

// MARK: - Post Service Implementation

struct PostService: PostServicing {
    private let networkService: NetworkService

    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }

    func fetchUserPosts(userId: String, next: String? = nil, limit: Int? = nil, category: PostCategory? = nil) async throws -> PostListDTO {
        try await networkService.request(
            PostRouter.fetchUserPosts(userId: userId, next: next, limit: limit, category: category),
            responseType: PostListDTO.self
        )
    }

    func fetchMyLikedPosts(next: String? = nil, limit: Int? = nil, category: PostCategory? = nil) async throws -> PostListDTO {
        try await networkService.request(
            PostRouter.fetchMyLikedPosts(next: next, limit: limit, category: category),
            responseType: PostListDTO.self
        )
    }

    func fetchPost(postId: String) async throws -> PostDTO {
        try await networkService.request(
            PostRouter.fetchPost(postId: postId),
            responseType: PostDTO.self
        )
    }

    func likePost(postId: String) async throws -> LikeStatusDTO {
        try await networkService.request(
            PostRouter.likePost(postId: postId),
            responseType: LikeStatusDTO.self
        )
    }
}
