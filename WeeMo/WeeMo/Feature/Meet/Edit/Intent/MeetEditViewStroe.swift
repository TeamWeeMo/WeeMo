//
//  MeetViewModel.swift
//  WeeMo
//
//  Created by 차지용 on 11/14/25.
//

import Foundation
import Combine
import SwiftUI
import PhotosUI

// MARK: - Meet ViewModel

final class MeetEditViewStroe: ObservableObject {
    @Published var state = MeetEditState()
    @Published var selectedPhotoItems: [PhotosPickerItem] = []
    @Published var selectedImages: [UIImage] = []
    private let networkService = NetworkService()

    func handle(_ intent: MeetEditIntent) {
        switch intent {
        case .loadSpaces:
            loadSpaces()
        case .selectSpace(let space):
            state.selectedSpace = space
        case .retryLoadSpaces:
            loadSpaces()
        case .createMeet(let title, let description, let capacity, let price, let gender, let selectedSpace, let startDate):
            createMeet(title: title, description: description, capacity: capacity, price: price, gender: gender, selectedSpace: selectedSpace, startDate: startDate)
        case .retryCreateMeet:
            // TODO: 이전 매개변수로 다시 시도
            break
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
                let router = PostRouter.fetchPosts(next: nil, limit: nil, category: .space)
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

                // 임시로 Data로 먼저 받아서 응답 확인
                let urlRequest = try router.asURLRequest()
                let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)

                print("📋 Raw response data:")
                if let responseString = String(data: data, encoding: .utf8) {
                    print(responseString)
                } else {
                    print("Unable to convert response to string")
                }

                // JSON 디코딩 시도
                let response = try JSONDecoder().decode(PostListDTO.self, from: data)

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
                        rating: Double(postDTO.value1 ?? "4") ?? 4.5, // value1을 rating으로 사용
                        pricePerHour: postDTO.price ?? 1234,
                        category: .cafe, // 기본값, 필요시 postDTO의 다른 필드로 매핑
                        isPopular: false,
                        amenities: [], // 필요시 postDTO의 다른 필드로 매핑
                        hasParking: false, // 필요시 postDTO의 다른 필드로 매핑
                        description: postDTO.content,
                        latitude: postDTO.geolocation.latitude,
                        longitude: postDTO.geolocation.longitude,
                        hashTags: []
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
                    if error.localizedDescription.contains("sesac_memolease only") {
                        state.spacesErrorMessage = "서버 설정 문제가 있습니다. 관리자에게 문의하세요."
                    } else {
                        state.spacesErrorMessage = error.localizedDescription
                    }
                    state.isLoadingSpaces = false
                }
            }
        }
    }

    private func createMeet(title: String, description: String, capacity: Int, price: String, gender: String, selectedSpace: Space?, startDate: Date) {
        guard !title.isEmpty else {
            state.createMeetErrorMessage = "모임 제목을 입력해주세요"
            return
        }

        guard !description.isEmpty else {
            state.createMeetErrorMessage = "모임 소개를 입력해주세요"
            return
        }

        state.isCreatingMeet = true
        state.createMeetErrorMessage = nil

        Task {
            do {
                // ISO8601 날짜 형식으로 변환
                let formatter = ISO8601DateFormatter()
                let startDateString = formatter.string(from: startDate)

                // 모임 내용에 장소와 날짜 정보 포함
                var fullDescription = description
                if let space = selectedSpace {
                    fullDescription += "\n\n📍 모임 장소: \(space.title)"
                }
                fullDescription += "\n⏰ 모임 시작일: \(DateFormatter.displayFormatter.string(from: startDate))"

                // 추가 필드들 (value1~10)
                var additionalFields: [String: String] = [:]
                additionalFields["value1"] = String(capacity) // 모집 인원
                additionalFields["value2"] = gender // 성별 제한
                additionalFields["value3"] = price // 참가 비용
                if let spaceId = selectedSpace?.id {
                    additionalFields["value4"] = spaceId // 선택된 공간 ID
                }
                additionalFields["value5"] = startDateString // 모임 시작일

                // 업로드된 이미지가 있으면 사용, 없으면 선택된 공간의 이미지를 사용
                var files = selectedSpace?.imageURLs ?? []

                // TODO: 실제 이미지 업로드 구현 필요
                // 현재는 선택된 공간의 이미지를 사용하지만, 향후 실제 이미지 업로드 API와 연동 필요
                if !selectedImages.isEmpty {
                    // 실제 구현에서는 이미지를 서버에 업로드하고 URL을 받아와야 함
                    print("📸 사용자가 선택한 이미지 \(selectedImages.count)개가 있습니다. 이미지 업로드 API 연동 필요")
                }

                let response = try await networkService.request(
                    PostRouter.createPost(
                        title: title,
                        price: 0,
                        content: fullDescription,
                        category: .meet,
                        files: files,
                        additionalFields: additionalFields,
                        latitude: selectedSpace?.latitude,
                        longitude: selectedSpace?.longitude
                    ),
                    responseType: PostDTO.self
                )

                await MainActor.run {
                    print("✅ 모임이 성공적으로 생성되었습니다: \(response.title)")
                    state.isCreatingMeet = false
                    state.isMeetCreated = true
                }

            } catch {
                await MainActor.run {
                    print("❌ 모임 생성 실패: \(error)")
                    state.createMeetErrorMessage = error.localizedDescription
                    state.isCreatingMeet = false
                }
            }
        }
    }
}
