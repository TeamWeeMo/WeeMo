//
//  SpaceListStore.swift
//  WeeMo
//
//  Created by Reimos on 11/15/25
//

import Foundation
import Combine

// MARK: - Space List Store

/// SpaceList의 비즈니스 로직과 상태 관리를 담당하는 Store (MVI)
final class SpaceListStore: ObservableObject {
    // MARK: - Published State

    @Published private(set) var state = SpaceListState()

    // MARK: - Dependencies

    private let networkService: NetworkService

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer

    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Intent Handler

    /// Intent를 받아 State를 변경하는 단방향 흐름
    func send(_ intent: SpaceListIntent) {
        switch intent {
        case .viewAppeared:
            handleViewAppeared()

        case .searchTextChanged(let text):
            handleSearchTextChanged(text)

        case .categoryChanged(let category):
            handleCategoryChanged(category)

        case .refresh:
            handleRefresh()
        }
    }

    // MARK: - Private Intent Handlers

    private func handleViewAppeared() {
        // 이미 데이터가 있으면 재호출 안함
        guard state.allSpaces.isEmpty else { return }

        fetchSpaces()
    }

    private func handleSearchTextChanged(_ text: String) {
        state.searchText = text
        // filteredSpaces는 computed property로 자동 계산됨
    }

    private func handleCategoryChanged(_ category: SpaceCategory) {
        state.selectedCategory = category
        // filteredSpaces는 computed property로 자동 계산됨
    }

    private func handleRefresh() {
        fetchSpaces()
    }

    // MARK: - Network Requests

    /// 서버에서 Space 카테고리 게시글 조회
    private func fetchSpaces() {
        // 로딩 시작
        state.isLoading = true
        state.errorMessage = nil

        // PostRouter를 통해 API 호출
        Task {
            do {
                let response: PostListDTO = try await networkService.request(
                    PostRouter.fetchPosts(
                        next: nil,
                        limit: 20,
                        category: .space // Space 카테고리만 조회
                    ),
                    responseType: PostListDTO.self
                )

                // DTO → Domain Model 변환
                let spaces = response.data.map { $0.toSpace() }

                // 메인 스레드에서 State 업데이트
                await MainActor.run {
                    self.state.allSpaces = spaces
                    self.state.isLoading = false
                }

            } catch {
                // 네트워크 에러 처리
                await MainActor.run {
                    self.state.isLoading = false
                    self.state.errorMessage = (error as? NetworkError)? .localizedDescription ?? "공간 정보를 불러오는데 실패했습니다."
                }
            }
        }
    }
}
