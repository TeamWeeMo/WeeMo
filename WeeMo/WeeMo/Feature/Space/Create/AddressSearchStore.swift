//
//  AddressSearchViewModel.swift
//  WeeMo
//
//  Created by Reimos on 2025/11/19.
//

import Foundation
import Combine

// MARK: - Address Search State

struct AddressSearchState {
    var searchResults: [AddressSearchResult] = []
    var isSearching: Bool = false
    var showResults: Bool = false
    var errorMessage: String?
}

// MARK: - Address Search Intent

enum AddressSearchIntent {
    case search(String)
    case resultSelected(AddressSearchResult)
    case clearResults
    case showResultsChanged(Bool)
}

// MARK: - Address Search Store

final class AddressSearchStore: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var state = AddressSearchState()

    // MARK: - Private Properties
    private let kakaoService = KakaoLocalService()
    private var searchTask: Task<Void, Never>?

    // MARK: - Intent Handler

    func send(_ intent: AddressSearchIntent) {
        switch intent {
        case .search(let query):
            handleSearch(query: query)

        case .resultSelected:
            state.showResults = false
            state.searchResults = []

        case .clearResults:
            handleClearResults()

        case .showResultsChanged(let show):
            state.showResults = show
        }
    }

    // MARK: - Private Handlers

    /// 주소 검색 (버튼 클릭 시 호출)
    private func handleSearch(query: String) {
        // 이전 검색 취소
        searchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            state.searchResults = []
            state.isSearching = false
            return
        }

        state.isSearching = true
        state.showResults = true

        searchTask = Task {
            do {
                let results = try await kakaoService.searchAddress(query: query)

                await MainActor.run {
                    self.state.searchResults = results
                    self.state.isSearching = false
                }
            } catch {
                print("[AddressSearchStore] 검색 에러: \(error)")
                await MainActor.run {
                    self.state.searchResults = []
                    self.state.isSearching = false
                    self.state.errorMessage = "검색 중 오류가 발생했습니다."
                }
            }
        }
    }

    /// 검색 결과 초기화
    private func handleClearResults() {
        searchTask?.cancel()
        state.searchResults = []
        state.isSearching = false
        state.showResults = false
    }
}
