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

        case .spaceSelected(let space):
            handleSpaceSelected(space)

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

    private func handleSpaceSelected(_ space: Space) {
        // Navigation은 View에서 처리
        print("[SpaceListStore] 공간 선택됨: \(space.title)")
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

        // 디버깅: SeSACKey 확인
        if let sesacKey = Bundle.main.object(forInfoDictionaryKey: "SeSACKey") as? String {
            print("[SpaceListStore] SeSACKey 확인됨: \(sesacKey.prefix(10))...")
        } else {
            print("[SpaceListStore] SeSACKey를 Info.plist에서 읽을 수 없습니다!")
        }

        // 디버깅: AccessToken 확인
        if let token = UserDefaults.standard.string(forKey: "accessToken") {
            print("[SpaceListStore] AccessToken 확인됨: \(token.prefix(20))...")
        } else {
            print("[SpaceListStore] AccessToken이 없습니다!")
        }

        // PostRouter를 통해 API 호출
        Task {
            do {
                let response: PostListDTO = try await networkService.request(
                    PostRouter.fetchPosts(
                        next: nil,
                        limit: 100, // 충분히 많은 데이터 가져오기
                        category: .space // Space 카테고리만 조회
                    ),
                    responseType: PostListDTO.self
                )

                // DTO → Domain Model 변환
                let spaces = response.data.map { $0.toSpace() }

                // 디버깅: 첫 번째 공간 데이터 확인
                if let firstSpace = spaces.first {
                    print("[SpaceListStore] 첫 번째 공간 제목: \(firstSpace.title)")
                    print("[SpaceListStore] 주소: \(firstSpace.address)")
                    print("[SpaceListStore] 평점: \(firstSpace.rating)")
                    print("[SpaceListStore] 인기 공간: \(firstSpace.isPopular)")
                    print("[SpaceListStore] 이미지 URLs: \(firstSpace.imageURLs)")
                }

                // 디버깅: 인기 공간 개수 확인
                let popularCount = spaces.filter { $0.isPopular }.count
                print("[SpaceListStore] 인기 공간 개수: \(popularCount)")

                // 메인 스레드에서 State 업데이트
                await MainActor.run {
                    self.state.allSpaces = spaces
                    self.state.isLoading = false
                    print("[SpaceListStore] 공간 \(spaces.count)개 로드 완료")
                }

            } catch let error as NetworkError {
                // 네트워크 에러 처리
                await MainActor.run {
                    self.state.isLoading = false
                    self.state.errorMessage = error.localizedDescription
                    print("[SpaceListStore] 네트워크 에러: \(error)")
                    print("[SpaceListStore] 에러 설명: \(error.localizedDescription)")
                }

            } catch {
                // 기타 에러 처리 (디코딩 에러 등)
                await MainActor.run {
                    self.state.isLoading = false
                    self.state.errorMessage = "알 수 없는 오류가 발생했습니다."
                    print("[SpaceListStore] 알 수 없는 에러 타입: \(type(of: error))")
                    print("[SpaceListStore] 알 수 없는 에러 내용: \(error)")
                    print("[SpaceListStore] 알 수 없는 에러 localizedDescription: \(error.localizedDescription)")
                }
            }
        }
    }
}
