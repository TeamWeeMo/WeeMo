//
//  CommentStore.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/16/25.
//

import Foundation
import Combine

// MARK: - Comment Store

@Observable
final class CommentStore {
    // MARK: - Properties

    private(set) var state: CommentState

    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // Combine Subjects
    private let submitCommentSubject = PassthroughSubject<Void, Never>()

    // MARK: - Initializer

    init(
        postId: String,
        networkService: NetworkServiceProtocol = NetworkService()
    ) {
        self.state = CommentState(postId: postId)
        self.networkService = networkService

        setupCommentDebounce()
    }

    // MARK: - Intent Handler

    func send(_ intent: CommentIntent) {
        switch intent {
        case .onAppear:
            Task { await fetchComments() }

        case .updateComment(let text):
            state.commentText = text

        case .submitComment:
            submitCommentSubject.send()  // Debounced

        case .deleteComment(let commentId):
            Task { await deleteComment(commentId) }

        case .refreshComments:
            Task { await fetchComments() }
        }
    }

    // MARK: - Setup

    private func setupCommentDebounce() {
        submitCommentSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.submitComment()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    @MainActor
    private func fetchComments() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            let response = try await networkService.request(
                CommentRouter.fetchComments(postId: state.postId),
                responseType: CommentListDTO.self
            )

            state.comments = response.data.toDomain()
            state.isLoading = false

            print("댓글 로드 성공: \(state.comments.count)개")
        } catch {
            state.isLoading = false
            state.errorMessage = "댓글을 불러오는데 실패했습니다."

            print("댓글 로드 실패: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func submitComment() async {
        guard state.canSubmit else { return }

        let commentContent = state.commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        state.isSubmitting = true
        state.errorMessage = nil

        do {
            let newComment = try await networkService.request(
                CommentRouter.createComment(postId: state.postId, content: commentContent),
                responseType: CommentDTO.self
            )

            // 댓글 작성 성공 후 입력창 초기화
            state.commentText = ""
            state.isSubmitting = false

            // 새 댓글을 목록에 추가 (서버 응답 사용)
            state.comments.append(newComment.toDomain())

            print("댓글 작성 성공")
        } catch {
            state.isSubmitting = false
            state.errorMessage = "댓글 작성에 실패했습니다."

            print("댓글 작성 실패: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func deleteComment(_ commentId: String) async {
        state.errorMessage = nil

        do {
            try await networkService.request(
                CommentRouter.deleteComment(postId: state.postId, commentId: commentId)
            )

            // 댓글 삭제 후 목록 새로고침
            await fetchComments()

            print("댓글 삭제 성공")
        } catch {
            state.errorMessage = "댓글 삭제에 실패했습니다."

            print("댓글 삭제 실패: \(error.localizedDescription)")
        }
    }
}
