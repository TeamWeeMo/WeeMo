//
//  CommentService.swift
//  WeeMo
//
//  Created by Reimos on 2025/11/23.
//

import Foundation

// MARK: - Comment Service Protocol

protocol CommentServicing {
    /// 댓글 목록 조회
    func fetchComments(postId: String) async throws -> [CommentDTO]

    /// 댓글 작성
    func createComment(postId: String, content: String) async throws -> CommentDTO

    /// 댓글 수정
    func updateComment(postId: String, commentId: String, content: String) async throws -> CommentDTO

    /// 댓글 삭제
    func deleteComment(postId: String, commentId: String) async throws
}

// MARK: - Comment Service Implementation

struct CommentService: CommentServicing {
    private let networkService: NetworkService

    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }

    func fetchComments(postId: String) async throws -> [CommentDTO] {
        let response = try await networkService.request(
            CommentRouter.fetchComments(postId: postId),
            responseType: CommentListDTO.self
        )
        return response.data
    }

    func createComment(postId: String, content: String) async throws -> CommentDTO {
        try await networkService.request(
            CommentRouter.createComment(postId: postId, content: content),
            responseType: CommentDTO.self
        )
    }

    func updateComment(postId: String, commentId: String, content: String) async throws -> CommentDTO {
        try await networkService.request(
            CommentRouter.updateComment(postId: postId, commentId: commentId, content: content),
            responseType: CommentDTO.self
        )
    }

    func deleteComment(postId: String, commentId: String) async throws {
        try await networkService.request(
            CommentRouter.deleteComment(postId: postId, commentId: commentId)
        )
    }
}
