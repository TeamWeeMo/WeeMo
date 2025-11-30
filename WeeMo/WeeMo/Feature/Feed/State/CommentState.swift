//
//  CommentState.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/16/25.
//

import Foundation

// MARK: - Comment State

struct CommentState {
    // 게시글 정보
    let postId: String

    // 댓글 데이터
    var comments: [Comment] = []

    // 입력 상태
    var commentText: String = ""

    // 로딩/에러
    var isLoading: Bool = false
    var isSubmitting: Bool = false
    var errorMessage: String?

    // 초기화
    init(postId: String) {
        self.postId = postId
    }

    /// 댓글이 비어있는지 여부
    var isEmpty: Bool {
        comments.isEmpty && !isLoading
    }

    /// 제출 가능 여부
    var canSubmit: Bool {
        !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSubmitting
    }
}
