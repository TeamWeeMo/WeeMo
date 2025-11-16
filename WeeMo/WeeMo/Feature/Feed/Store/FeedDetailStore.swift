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

    // Combine Subjects
    private let likeSubject = PassthroughSubject<Void, Never>()

    // MARK: - Initializer

    init(
        feed: Feed,
        networkService: NetworkServiceProtocol = NetworkService()
    ) {
        self.state = FeedDetailState(feed: feed)
        self.networkService = networkService

        setupLikeDebounce()
    }

    // MARK: - Intent Handler

    func send(_ intent: FeedDetailIntent) {
        switch intent {
        case .onAppear:
            handleOnAppear()

        case .toggleLike:
            likeSubject.send()  // Debounced

        case .openComments:
            handleOpenComments()

        case .closeComments:
            state.showCommentSheet = false

        case .sharePost:
            handleSharePost()
            
        case .showMoreMenu:
            handleShowMoreMenu()

        case .navigateToProfile:
            handleNavigateToProfile()

        case .changeImagePage(let index):
            state.currentImageIndex = index
        }
    }

    // MARK: - Setup

    private func setupLikeDebounce() {
        likeSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.toggleLike()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    private func handleOnAppear() {
        // 초기 로드 (필요 시)
        // TODO: 서버에서 최신 좋아요 상태 가져오기
    }

    @MainActor
    private func toggleLike() async {
        // 낙관적 업데이트 (Optimistic Update)
        let previousLikeState = state.isLiked
        let previousLikeCount = state.likeCount

        state.isLiked.toggle()
        state.likeCount += state.isLiked ? 1 : -1

        // 토글된 상태를 서버에 전송
        let newLikeStatus = state.isLiked

        do {
            let response = try await networkService.request(
                PostRouter.likePost(postId: state.feed.id, likeStatus: newLikeStatus),
                responseType: LikeStatusDTO.self
            )

            // 서버 응답과 로컬 상태 동기화
            state.isLiked = response.likeStatus

            print("좋아요 성공: \(state.isLiked)")
        } catch {
            // 실패 시 롤백
            state.isLiked = previousLikeState
            state.likeCount = previousLikeCount
            state.errorMessage = "좋아요 처리에 실패했습니다."

            print("좋아요 실패: \(error.localizedDescription)")
        }
    }

    private func handleOpenComments() {
        state.showCommentSheet = true
        print("댓글 바텀 시트 열기")
    }

    private func handleSharePost() {
        // TODO: 공유하기
        print("공유하기")
    }
    
    private func handleShowMoreMenu() {
        // TODO: 더보기
        print("더보기 메뉴")
    }

    private func handleNavigateToProfile() {
        // TODO: 프로필 화면으로 이동
        print("프로필로 이동: \(state.feed.creator.nickname)")
    }
}
