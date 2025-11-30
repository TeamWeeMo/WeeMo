//
//  FeedStore.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/15/25.
//

import Foundation
import Combine
import UIKit

// MARK: - Feed Store

@Observable
final class FeedStore {
    // MARK: - Properties

    private(set) var state = FeedState()

    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // 임시 토큰 (로그인 기능 완성 전까지 사용)
    private let temporaryToken: String

    // 페이지네이션 설정
    private let pageLimit = 20

    // 무한 스크롤 쓰로틀링용 Subject
    private let loadMoreSubject = PassthroughSubject<Void, Never>()

    // MARK: - Initializer

    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        temporaryToken: String = ""
    ) {
        self.networkService = networkService
        self.temporaryToken = temporaryToken

        // 임시 토큰을 UserDefaults에 저장 (APIRouter에서 사용)
        if !temporaryToken.isEmpty {
            UserDefaults.standard.set(temporaryToken, forKey: "accessToken")
        }

        // 무한 스크롤 쓰로틀링 설정 (1초에 최대 1회만 실행)
        loadMoreSubject
            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                Task {
                    await self?.loadMoreFeeds()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Intent Handler

    func send(_ intent: FeedIntent) {
        switch intent {
        case .onAppear:
            handleOnAppear()

        case .selectFeed(let feed):
            state.selectedFeed = feed

        case .deselectFeed:
            state.selectedFeed = nil

        case .createNewFeed:
            state.isShowingEditView = true

        case .dismissEditView:
            state.isShowingEditView = false

        case .loadMore:
            // Combine의 throttle을 통해 1초에 최대 1회만 실행
            loadMoreSubject.send(())

        case .loadFeedsSuccess(let feeds):
            handleLoadFeedsSuccess(feeds)

        case .loadFeedsFailed(let error):
            handleLoadFeedsFailed(error)

        case .loadMoreSuccess(let feeds, let nextCursor):
            handleLoadMoreSuccess(feeds, nextCursor: nextCursor)

        case .loadMoreFailed(let error):
            handleLoadMoreFailed(error)
        }
    }

    // MARK: - Public Methods (Async)

    /// 새로고침 (View에서 직접 호출)
    @MainActor
    func refresh() async {
        await refreshFeeds()
    }

    // MARK: - Private Methods

    private func handleOnAppear() {
        // 초기 로드 (필요 시)
        if state.feeds.isEmpty {
            Task {
                await loadFeeds()
            }
        }
    }

    /// 피드 목록 로드
    private func loadFeeds() async {
        await MainActor.run {
            state.isLoading = true
            state.errorMessage = nil
        }

        do {
            let response = try await networkService.request(
                PostRouter.fetchPosts(next: nil, limit: pageLimit, category: .feed),
                responseType: PostListDTO.self
            )

            // DTO → Domain 변환
            let feeds = response.data.map { $0.toFeed() }

            await MainActor.run {
                state.isLoading = false
                state.feeds = feeds
                state.nextCursor = response.nextCursor
            }

        } catch {
            await MainActor.run {
                state.isLoading = false
                state.errorMessage = (error as? NetworkError)?.localizedDescription ?? "피드를 불러오는데 실패했습니다."
            }
        }
    }

    /// 피드 새로고침
    private func refreshFeeds() async {
        await MainActor.run {
            state.isRefreshing = true
            state.errorMessage = nil
        }

        do {
            let response = try await networkService.request(
                PostRouter.fetchPosts(next: nil, limit: pageLimit, category: .feed),
                responseType: PostListDTO.self
            )

            // DTO → Domain 변환
            let feeds = response.data.map { $0.toFeed() }

            await MainActor.run {
                state.isRefreshing = false
                state.feeds = feeds
                state.nextCursor = response.nextCursor
            }

        } catch {
            await MainActor.run {
                state.isRefreshing = false
                state.errorMessage = (error as? NetworkError)?.localizedDescription ?? "피드를 새로고침하는데 실패했습니다."
            }
        }
    }

    /// 더 많은 피드 로드 (페이지네이션)
    private func loadMoreFeeds() async {
        guard state.hasMore, !state.isLoadingMore else { return }

        await MainActor.run {
            state.isLoadingMore = true
        }

        do {
            let response = try await networkService.request(
                PostRouter.fetchPosts(next: state.nextCursor, limit: pageLimit, category: .feed),
                responseType: PostListDTO.self
            )

            // DTO → Domain 변환
            let newFeeds = response.data.map { $0.toFeed() }

            await MainActor.run {
                state.isLoadingMore = false

                // 중복 제거: 이미 존재하는 ID는 제외
                let existingIDs = Set(state.feeds.map { $0.id })
                let uniqueNewFeeds = newFeeds.filter { !existingIDs.contains($0.id) }

                state.feeds.append(contentsOf: uniqueNewFeeds)
                state.nextCursor = response.nextCursor
            }

        } catch {
            await MainActor.run {
                state.isLoadingMore = false
                // 페이지네이션 에러는 조용히 실패 (사용자에게 방해하지 않음)
                print("더 많은 피드 로드 실패: \(error.localizedDescription)")
            }
        }
    }

    private func handleLoadFeedsSuccess(_ feeds: [Feed]) {
        state.feeds = feeds
        state.isLoading = false
    }

    private func handleLoadFeedsFailed(_ error: Error) {
        state.isLoading = false
        state.errorMessage = (error as? NetworkError)?.localizedDescription ?? "피드를 불러오는데 실패했습니다."
    }

    private func handleLoadMoreSuccess(_ feeds: [Feed], nextCursor: String?) {
        state.feeds.append(contentsOf: feeds)
        state.nextCursor = nextCursor
        state.isLoadingMore = false
    }

    private func handleLoadMoreFailed(_ error: Error) {
        state.isLoadingMore = false
        print("더 많은 피드 로드 실패: \(error.localizedDescription)")
    }
}
