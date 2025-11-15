//
//  MeetListViewModel.swift
//  WeeMo
//
//  Created by 차지용 on 11/16/25.
//

import Foundation
import Combine

// MARK: - Meet List Intent

enum MeetListIntent {
    case loadMeets
    case retryLoadMeets
    case searchMeets(query: String)
    case refreshMeets
}

// MARK: - Meet List State

struct MeetListState {
    var meets: [Meet] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var searchQuery: String = ""
}

// MARK: - Meet List ViewModel

final class MeetListViewModel: ObservableObject {
    @Published var state = MeetListState()
    private let networkService = NetworkService()

    func handle(_ intent: MeetListIntent) {
        switch intent {
        case .loadMeets:
            loadMeets()
        case .retryLoadMeets:
            loadMeets()
        case .searchMeets(let query):
            state.searchQuery = query
            // TODO: 검색 기능 구현
        case .refreshMeets:
            loadMeets()
        }
    }

    private func loadMeets() {
        state.isLoading = true
        state.errorMessage = nil

        Task {
            do {
                let response = try await networkService.request(
                    PostRouter.fetchPosts(next: nil, limit: nil, category: .meet),
                    responseType: PostListDTO.self
                )

                let meets = response.data.compactMap { (postDTO: PostDTO) -> Meet? in
                    // PostDTO를 Meet으로 변환
                    // value1: 모집 인원, value2: 성별 제한, value3: 참가 비용, value4: 공간 ID
                    return Meet(
                        title: postDTO.title,
                        date: formatDate(postDTO.createdAt),
                        location: "모임 장소", // TODO: 공간 정보에서 가져오기
                        address: postDTO.content,
                        price: formatPrice(postDTO.value3),
                        participants: formatParticipants(postDTO.value1, postDTO.buyers.count),
                        imageName: postDTO.files.first ?? "",
                        daysLeft: calculateDaysLeft(postDTO.createdAt)
                    )
                }

                await MainActor.run {
                    state.meets = meets
                    state.isLoading = false
                }

            } catch {
                await MainActor.run {
                    state.errorMessage = error.localizedDescription
                    state.isLoading = false
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "날짜 미정" }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "M월 d일 (E)"
        displayFormatter.locale = Locale(identifier: "ko_KR")
        return displayFormatter.string(from: date)
    }

    private func formatPrice(_ priceString: String?) -> String {
        guard let priceString = priceString,
              let price = Int(priceString) else { return "무료" }

        if price == 0 {
            return "무료"
        } else {
            return "\(price)원"
        }
    }

    private func formatParticipants(_ capacityString: String?, _ currentCount: Int) -> String {
        guard let capacityString = capacityString,
              let capacity = Int(capacityString) else { return "\(currentCount)명 참여" }

        return "\(currentCount)/\(capacity)명"
    }

    private func calculateDaysLeft(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "" }

        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: now, to: date)

        if let days = components.day {
            if days < 0 {
                return "진행 완료"
            } else if days == 0 {
                return "오늘"
            } else {
                return "D-\(days)"
            }
        }
        return ""
    }
}
