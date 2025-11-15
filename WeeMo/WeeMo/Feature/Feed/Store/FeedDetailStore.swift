//
//  FeedDetailStore.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/15/25.
//

import Foundation
import Combine

// MARK: - Feed Detail Store

@Observable
final class FeedDetailStore {
    // MARK: - Properties

    private(set) var state: FeedDetailState

    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer

    init(
        feed: Feed,
        networkService: NetworkServiceProtocol = NetworkService()
    ) {
        self.state = FeedDetailState(feed: feed)
        self.networkService = networkService
    }

    // MARK: - Intent Handler

    func send(_ intent: FeedDetailIntent) {
        switch intent {
        case .onAppear:
            handleOnAppear()

        case .toggleLike:
            toggleLike()

        case .sharePost:
            handleSharePost()

        case .openComments:
            handleOpenComments()

        case .toggleBookmark:
            toggleBookmark()

        case .showMoreMenu:
            handleShowMoreMenu()

        case .navigateToProfile:
            handleNavigateToProfile()

        case .changeImagePage(let index):
            state.currentImageIndex = index
        }
    }

    // MARK: - Private Methods

    private func handleOnAppear() {
        // 초기 로드 (필요 시)
        // TODO: 서버에서 최신 좋아요/북마크 상태 가져오기
    }

    private func toggleLike() {
        // 낙관적 업데이트 (Optimistic Update)
        state.isLiked.toggle()
        state.likeCount += state.isLiked ? 1 : -1

        // TODO: 서버에 좋아요 API 호출
        // Task {
        //     do {
        //         try await networkService.request(
        //             PostRouter.likePost(postId: state.feed.id),
        //             responseType: LikeDTO.self
        //         )
        //     } catch {
        //         // 실패 시 롤백
        //         state.isLiked.toggle()
        //         state.likeCount += state.isLiked ? 1 : -1
        //         state.errorMessage = "좋아요 처리에 실패했습니다."
        //     }
        // }

        print("좋아요 토글: \(state.isLiked)")
    }

    private func toggleBookmark() {
        // 낙관적 업데이트
        state.isBookmarked.toggle()

        // TODO: 서버에 북마크 API 호출
        print("북마크 토글: \(state.isBookmarked)")
    }

    private func handleSharePost() {
        // TODO: 공유 기능 구현
        print("공유하기: \(state.feed.id)")
    }

    private func handleOpenComments() {
        // TODO: 댓글 화면으로 이동
        print("댓글 열기")
    }

    private func handleShowMoreMenu() {
        // TODO: 더보기 메뉴 (수정/삭제/신고)
        print("더보기 메뉴")
    }

    private func handleNavigateToProfile() {
        // TODO: 프로필 화면으로 이동
        print("프로필로 이동: \(state.feed.creator.nickname)")
    }
}
