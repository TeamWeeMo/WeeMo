//
//  MeetListViewStore.swift
//  WeeMo
//
//  Created by 차지용 on 11/16/25.
//

import Foundation
import Combine

// MARK: - Meet List Store

@Observable
final class MeetListStore {
    // MARK: - Properties

    private(set) var state = MeetListState()
    private let networkService: NetworkServiceProtocol

    // MARK: - Initializer

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Intent Handler

    func send(_ intent: MeetListIntent) {
        switch intent {
        case .loadMeets:
            Task { await loadMeets() }
        case .retryLoadMeets:
            Task { await loadMeets() }
        case .searchMeets(let query):
            searchMeets(query: query)
        case .refreshMeets:
            Task { await refreshMeets() }
        case .sortMeets(let option):
            sortMeets(by: option)
        case .loadMoreMeets:
            Task { await loadMoreMeets() }
        }
    }

    // MARK: - Private Methods

    private func loadMeets() async {
        await MainActor.run {
            state.isLoading = true
            state.errorMessage = nil
            state.nextCursor = nil
            state.hasMoreData = true
        }

        do {
            let response = try await networkService.request(
                PostRouter.fetchPosts(next: nil, limit: 20, category: .meet),
                responseType: PostListDTO.self
            )

            // Mapper를 사용하여 변환
            let meets = response.data.map { $0.toMeet() }

            await MainActor.run {
                state.allMeets = meets
                state.filteredMeets = meets
                state.nextCursor = response.nextCursor
                state.hasMoreData = response.nextCursor != nil
                state.isLoading = false
                applyFilterAndSort()
            }

        } catch {
            await MainActor.run {
                state.errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                state.isLoading = false
            }
        }
    }

    /// 새로고침 (화면 복귀 시 사용 및 Pull-to-Refresh)
    func refreshMeets() async {
        // 로딩 인디케이터 없이 조용히 새로고침
        await MainActor.run {
            state.errorMessage = nil
            state.nextCursor = nil
            state.hasMoreData = true
        }

        do {
            let response = try await networkService.request(
                PostRouter.fetchPosts(next: nil, limit: 20, category: .meet),
                responseType: PostListDTO.self
            )

            // Mapper를 사용하여 변환
            let meets = response.data.map { $0.toMeet() }

            await MainActor.run {
                state.allMeets = meets
                state.filteredMeets = meets
                state.nextCursor = response.nextCursor
                state.hasMoreData = response.nextCursor != nil
                applyFilterAndSort()
            }

        } catch {
            // 새로고침 실패는 조용히 처리 (기존 데이터 유지)
            print("[MeetListStore] 새로고침 실패: \(error)")
        }
    }

    private func searchMeets(query: String) {
        state.searchQuery = query
        applyFilterAndSort()
    }

    private func sortMeets(by option: SortOption) {
        state.currentSortOption = option
        applyFilterAndSort()
    }

    private func applyFilterAndSort() {
        // 1. 검색 필터 적용
        if state.searchQuery.isEmpty {
            state.filteredMeets = state.allMeets
        } else {
            state.filteredMeets = state.allMeets.filter { meet in
                let searchText = state.searchQuery.lowercased()
                return meet.title.lowercased().contains(searchText) ||
                       meet.spaceName.lowercased().contains(searchText) ||
                       meet.address.lowercased().contains(searchText)
            }
        }

        // 2. 정렬 적용
        switch state.currentSortOption {
        case .registrationDate:
            state.meets = state.filteredMeets.sorted { $0.createdAt > $1.createdAt }
        case .deadline:
            state.meets = state.filteredMeets.sorted { $0.daysUntilDeadline < $1.daysUntilDeadline }
        case .distance:
            state.meets = state.filteredMeets.sorted { ($0.distance ?? .infinity) < ($1.distance ?? .infinity) }
        }
    }

    private func loadMoreMeets() async {
        guard state.hasMoreData && !state.isLoadingMore,
              let nextCursor = state.nextCursor else {
            return
        }

        await MainActor.run {
            state.isLoadingMore = true
        }

        do {
            let response = try await networkService.request(
                PostRouter.fetchPosts(next: nextCursor, limit: 20, category: .meet),
                responseType: PostListDTO.self
            )

            // Mapper를 사용하여 변환
            let newMeets = response.data.map { $0.toMeet() }

            await MainActor.run {
                // 중복 제거
                let existingIds = Set(state.allMeets.map { $0.id })
                let uniqueNewMeets = newMeets.filter { !existingIds.contains($0.id) }

                state.allMeets.append(contentsOf: uniqueNewMeets)
                state.nextCursor = response.nextCursor
                state.hasMoreData = response.nextCursor != nil
                state.isLoadingMore = false

                applyFilterAndSort()
            }

        } catch {
            await MainActor.run {
                state.isLoadingMore = false
            }
        }
    }
}
