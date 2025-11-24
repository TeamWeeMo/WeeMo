//
//  MeetViewModel.swift
//  WeeMo
//
//  Created by 차지용 on 11/14/25.
//

import Foundation
import Combine

// MARK: - Meet ViewModel

final class MeetEditViewStroe: ObservableObject {
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
              
                let reponse = try await networkService.request(PostRouter.fetchPosts(next: nil, limit: nil, category: .space), responseType: PostListDTO.self)
               
                let spaces = reponse.data.map { $0.toSpace() }

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

                // 선택된 공간의 이미지를 사용
                let files = selectedSpace?.imageURLs ?? []

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
