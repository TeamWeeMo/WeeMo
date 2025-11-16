//
//  CommentIntent.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/16/25.
//

import Foundation

// MARK: - Comment Intent

enum CommentIntent {
    // 라이프사이클
    case onAppear

    // 댓글 작성
    case updateComment(String)
    case submitComment

    // 댓글 관리
    case deleteComment(String)
    case refreshComments
}
