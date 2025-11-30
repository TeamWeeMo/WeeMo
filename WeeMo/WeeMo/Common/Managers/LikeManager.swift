//
//  LikeManager.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/29/25.
//

import Foundation
import Combine

// MARK: - Like Manager

/// 좋아요 상태를 중앙에서 관리하는 싱글톤
@Observable
final class LikeManager {
    // MARK: - Singleton

    static let shared = LikeManager()

    // MARK: - Properties

    /// 좋아요한 게시글 ID 집합
    private(set) var likedPostIds: Set<String> = []

    /// 게시글별 좋아요 개수 캐시 (postId: likeCount)
    private(set) var likeCountCache: [String: Int] = [:]

    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    /// Debounce를 위한 Subject (postId별로 관리)
    private var likeSubjects: [String: PassthroughSubject<Void, Never>] = [:]

    // MARK: - Initializer

    private init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Public Methods

    /// 좋아요 상태 확인
    func isLiked(postId: String) -> Bool {
        likedPostIds.contains(postId)
    }

    /// 좋아요 개수 가져오기
    func likeCount(for postId: String) -> Int {
        likeCountCache[postId] ?? 0
    }

    /// 좋아요 상태 초기화 (게시글 로드 시 호출)
    func setLikeState(postId: String, isLiked: Bool, likeCount: Int) {
        if isLiked {
            likedPostIds.insert(postId)
        } else {
            likedPostIds.remove(postId)
        }
        likeCountCache[postId] = likeCount
    }

    /// 좋아요 토글 (Debounced)
    func toggleLike(postId: String) {
        // Subject가 없으면 생성하고 debounce 설정
        if likeSubjects[postId] == nil {
            let subject = PassthroughSubject<Void, Never>()
            likeSubjects[postId] = subject

            subject
                .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
                .sink { [weak self] _ in
                    Task { @MainActor [weak self] in
                        await self?.performToggleLike(postId: postId)
                    }
                }
                .store(in: &cancellables)
        }

        // Subject에 이벤트 전송
        likeSubjects[postId]?.send()
    }

    // MARK: - Private Methods

    @MainActor
    private func performToggleLike(postId: String) async {
        // 낙관적 업데이트 (Optimistic Update)
        let previousLikeState = likedPostIds.contains(postId)
        let previousLikeCount = likeCountCache[postId] ?? 0

        // 로컬 상태 즉시 업데이트
        let newLikeState = !previousLikeState
        if newLikeState {
            likedPostIds.insert(postId)
            likeCountCache[postId] = previousLikeCount + 1
        } else {
            likedPostIds.remove(postId)
            likeCountCache[postId] = max(0, previousLikeCount - 1)
        }

        // 서버에 요청
        do {
            let response = try await networkService.request(
                PostRouter.likePost(postId: postId, likeStatus: newLikeState),
                responseType: LikeStatusDTO.self
            )

            // 서버 응답과 로컬 상태 동기화
            if response.likeStatus {
                likedPostIds.insert(postId)
            } else {
                likedPostIds.remove(postId)
            }

            print("✅ [LikeManager] 좋아요 성공: postId=\(postId), isLiked=\(response.likeStatus)")

        } catch {
            // 실패 시 롤백
            if previousLikeState {
                likedPostIds.insert(postId)
            } else {
                likedPostIds.remove(postId)
            }
            likeCountCache[postId] = previousLikeCount

            print("❌ [LikeManager] 좋아요 실패: \(error.localizedDescription)")
        }
    }
}
