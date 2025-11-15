//
//  MeetViewModel.swift
//  WeeMo
//
//  Created by 차지용 on 11/14/25.
//

import Foundation
import Combine

// MARK: - Meet ViewModel

final class MeetEditViewModel: ObservableObject {
    @Published var state = MeetEditState()
    private let networkService = NetworkService()

    func handle(_ intent: MeetEditIntent) {
        switch intent {
        case .loadSpaces:
            loadSpaces()
        case .selectSpace(let space):
            state.selectedSpace = space
        case .retryLoadSpaces:
            loadSpaces()
        }
    }

    private func loadSpaces() {
        state.isLoadingSpaces = true
        state.spacesErrorMessage = nil

        Task {
            do {
                print("🔄 Loading all posts to check available categories")

                // 토큰 확인
                if let token = UserDefaults.standard.string(forKey: "accessToken") {
                    print("🔑 Access token exists: \(String(token.prefix(20)))...")
                } else {
                    print("❌ No access token found")
                }

                // 요청 정보 로깅
                let router = PostRouter.fetchPosts(next: nil, limit: nil, category: nil)
                do {
                    let urlRequest = try router.asURLRequest()
                    print("📡 Request URL: \(urlRequest.url?.absoluteString ?? "nil")")
                    print("📡 Request Method: \(urlRequest.httpMethod ?? "nil")")
                    print("📡 Request Headers:")
                    urlRequest.allHTTPHeaderFields?.forEach { key, value in
                        print("   \(key): \(value)")
                    }
                } catch {
                    print("❌ Failed to create URL request: \(error)")
                }

                let response = try await networkService.request(
                    router,
                    responseType: PostListDTO.self
                ) as PostListDTO

                print("✅ API Response received: \(response.data.count) posts")
                print("📋 Categories in response: \(response.data.map { $0.category })")

                let spaces = response.data.compactMap { (postDTO: PostDTO) -> Space? in
                    print("🔍 Processing post: \(postDTO.title), category: \(postDTO.category)")

                    // space 카테고리만 필터링
                    guard postDTO.category == "space" else {
                        print("❌ Filtered out: \(postDTO.title) (category: \(postDTO.category))")
                        return nil
                    }

                    print("✅ Converting to Space: \(postDTO.title)")
                    // PostDTO를 Space로 변환
                    return Space(
                        id: postDTO.postId,
                        title: postDTO.title,
                        address: postDTO.content,
                        imageURLs: postDTO.files,
                        rating: Double(postDTO.value1) ?? 4.5, // value1을 rating으로 사용
                        pricePerHour: postDTO.price,
                        category: .cafe, // 기본값, 필요시 postDTO의 다른 필드로 매핑
                        isPopular: false,
                        amenities: [], // 필요시 postDTO의 다른 필드로 매핑
                        hasParking: false, // 필요시 postDTO의 다른 필드로 매핑
                        description: postDTO.content
                    )
                }

                print("🏠 Final spaces count: \(spaces.count)")

                await MainActor.run {
                    state.spaces = spaces
                    state.isLoadingSpaces = false
                }
            } catch {
                print("❌ Error loading spaces: \(error)")
                await MainActor.run {
                    state.spacesErrorMessage = error.localizedDescription
                    state.isLoadingSpaces = false
                }
            }
        }
    }
}
