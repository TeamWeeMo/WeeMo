//
//  MeetListViewModel.swift
//  WeeMo
//
//  Created by 차지용 on 11/16/25.
//

import Foundation
import Combine


final class MeetListViewStore: ObservableObject {
    @Published var state = MeetListState()
    private let networkService = NetworkService()

    func handle(_ intent: MeetListIntent) {
        switch intent {
        case .loadMeets:
            loadMeets()
        case .retryLoadMeets:
            loadMeets()
        case .searchMeets(let query):
            searchMeets(query: query)
        case .refreshMeets:
            loadMeets()
        case .sortMeets(let option):
            sortMeets(by: option)
        case .loadMoreMeets:
            loadMoreMeets()
        }
    }

    private func loadMeets() {
        state.isLoading = true
        state.errorMessage = nil
        state.nextCursor = nil // 초기 로드시 커서 리셋
        state.hasMoreData = true

        Task {
            do {
                let response = try await networkService.request(
                    PostRouter.fetchPosts(next: nil, limit: 20, category: .meet),
                    responseType: PostListDTO.self
                )

                let meets = response.data.compactMap { (postDTO: PostDTO) -> Meet? in
                    // PostDTO를 Meet으로 변환
                    // value1: 모집 인원, value2: 성별 제한, value3: 참가 비용, value4: 공간 ID, value5: 모임 시작일

                    // 모임 날짜 - value5(모임 시작일)가 있으면 사용, 없으면 생성일 사용
                    let meetDate = postDTO.value5 != nil ? formatDate(postDTO.value5!) : formatDate(postDTO.createdAt)

                    // 모임 장소 - content에서 📍 모임 장소: 부분 추출
                    let location = extractLocationFromContent(postDTO.content)

                    return Meet(
                        postId: postDTO.postId,
                        title: postDTO.title,
                        date: meetDate,
                        location: location,
                        address: postDTO.content,
                        price: formatPrice(postDTO.value3),
                        participants: formatParticipants(postDTO.value1, postDTO.buyers.count),
                        imageName: postDTO.files.first ?? "",
                        daysLeft: calculateDaysLeft(postDTO.value5 ?? postDTO.createdAt)
                    )
                }

                await MainActor.run {
                    state.allMeets = meets
                    state.filteredMeets = meets
                    state.nextCursor = response.nextCursor
                    state.hasMoreData = response.nextCursor != nil
                    state.isLoading = false
                    // 현재 검색어와 정렬 옵션 적용
                    applyFilterAndSort()
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

    private func extractLocationFromContent(_ content: String) -> String {
        // content에서 📍 모임 장소: 부분 찾기
        let pattern = "📍 모임 장소: (.*?)(?=\\n|$)"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)),
           let range = Range(match.range(at: 1), in: content) {
            return String(content[range])
        }
        return ""
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "" }
        return DateFormatter.simpleFormatter.string(from: date)
    }

    private func formatPrice(_ priceString: String?) -> String {
        guard let priceString = priceString,
              let price = Int(priceString) else { return "무료" }

        if price == 0 {
            return "무료"
        } else {
            return "\(price.formatted())원"
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

    private func searchMeets(query: String) {
        print("🔍 Searching meets with query: '\(query)'")
        state.searchQuery = query
        applyFilterAndSort()
    }

    private func sortMeets(by option: SortOption) {
        print("🔄 Sorting meets by: \(option.rawValue)")
        state.currentSortOption = option
        applyFilterAndSort()
    }

    private func applyFilterAndSort() {
        // 1. 먼저 검색 필터 적용
        if state.searchQuery.isEmpty {
            state.filteredMeets = state.allMeets
        } else {
            state.filteredMeets = state.allMeets.filter { meet in
                let searchText = state.searchQuery.lowercased()
                return meet.title.lowercased().contains(searchText) ||
                       meet.location.lowercased().contains(searchText) ||
                       meet.address.lowercased().contains(searchText)
            }
        }

        print("🔍 After filtering: \(state.filteredMeets.count) meets found")

        // 2. 정렬 적용
        switch state.currentSortOption {
        case .registrationDate:
            // 등록일순 - 제목 역순으로 테스트
            state.meets = state.filteredMeets.sorted { $0.title > $1.title }
            print("📋 Sorted by registration date: \(state.meets.map { $0.title })")
        case .deadline:
            // 마감일순 - daysLeft 기준 (D-day가 적은 순)
            state.meets = state.filteredMeets.sorted { meet1, meet2 in
                let days1 = parseDaysLeft(meet1.daysLeft)
                let days2 = parseDaysLeft(meet2.daysLeft)
                return days1 < days2
            }
            print("📋 Sorted by deadline: \(state.meets.map { "\($0.title) (\($0.daysLeft))" })")
        case .distance:
            // 거리순 - 가격순으로 테스트
            state.meets = state.filteredMeets.sorted { $0.price < $1.price }
            print("📋 Sorted by distance: \(state.meets.map { $0.title })")
        }

        print("✅ Filter & Sort completed. Final count: \(state.meets.count)")
    }

    // Helper function to parse date from string
    private func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.date(from: dateString) ?? Date.distantPast
    }

    // Helper function to parse days left from string
    private func parseDaysLeft(_ daysLeftString: String) -> Int {
        print("🔍 Parsing daysLeft: '\(daysLeftString)'")

        if daysLeftString == "오늘" {
            return 0
        } else if daysLeftString == "진행 완료" {
            return Int.max // 완료된 것은 맨 뒤로
        } else if daysLeftString.hasPrefix("D-") {
            let numberString = daysLeftString.replacingOccurrences(of: "D-", with: "")
            let result = Int(numberString) ?? Int.max
            print("✅ Parsed D-\(numberString) -> \(result)")
            return result
        }
        print("❌ Could not parse: '\(daysLeftString)' -> Int.max")
        return Int.max
    }

    // MARK: - Load More Data

    private func loadMoreMeets() {
        guard state.hasMoreData && !state.isLoadingMore,
              let nextCursor = state.nextCursor else {
            print("⚠️ No more data to load or already loading")
            return
        }

        state.isLoadingMore = true

        Task {
            do {
                print("🔄 Loading more meets with cursor: \(nextCursor)")

                let response = try await networkService.request(
                    PostRouter.fetchPosts(next: nextCursor, limit: 20, category: .meet),
                    responseType: PostListDTO.self
                )

                let newMeets = response.data.compactMap { (postDTO: PostDTO) -> Meet? in
                    // PostDTO를 Meet으로 변환 (기존과 동일한 로직)
                    let meetDate = postDTO.value5 != nil ? formatDate(postDTO.value5!) : formatDate(postDTO.createdAt)
                    let location = extractLocationFromContent(postDTO.content)

                    return Meet(
                        postId: postDTO.postId,
                        title: postDTO.title,
                        date: meetDate,
                        location: location.isEmpty ? "장소 미정" : location,
                        address: postDTO.content,
                        price: formatPrice(postDTO.value3),
                        participants: formatParticipants(postDTO.value1, postDTO.buyers.count),
                        imageName: postDTO.files.first ?? "",
                        daysLeft: calculateDaysLeft(postDTO.value5 ?? postDTO.createdAt)
                    )
                }

                await MainActor.run {
                    // 중복 제거하여 새로운 데이터만 추가
                    let existingPostIds = Set(state.allMeets.map { $0.postId })
                    let uniqueNewMeets = newMeets.filter { !existingPostIds.contains($0.postId) }

                    state.allMeets.append(contentsOf: uniqueNewMeets)
                    state.nextCursor = response.nextCursor
                    state.hasMoreData = response.nextCursor != nil
                    state.isLoadingMore = false

                    print("✅ Loaded \(uniqueNewMeets.count) new meets (filtered \(newMeets.count - uniqueNewMeets.count) duplicates). Total: \(state.allMeets.count)")

                    // 현재 검색어와 정렬 옵션 적용
                    applyFilterAndSort()
                }

            } catch {
                print("❌ Error loading more meets: \(error)")
                await MainActor.run {
                    state.isLoadingMore = false
                }
            }
        }
    }
}
