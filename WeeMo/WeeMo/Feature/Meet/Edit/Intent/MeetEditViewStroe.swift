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
    @Published var existingImageURLs: [String] = [] // 기존 이미지 URL들
    @Published var shouldKeepExistingImages: Bool = true // 기존 이미지 유지 여부
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
        case .loadMeetForEdit(let postId):
            loadMeetForEdit(postId: postId)
        case .updateMeet(let postId, let title, let description, let capacity, let price, let gender, let selectedSpace, let startDate):
            updateMeet(postId: postId, title: title, description: description, capacity: capacity, price: price, gender: gender, selectedSpace: selectedSpace, startDate: startDate)
        case .deleteMeet(let postId):
            deleteMeet(postId: postId)
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

                // 사용자가 선택한 이미지를 사용
                var files: [String] = []

                // 사용자가 선택한 이미지를 업로드
                if !selectedImages.isEmpty {
                    print("📸 사용자가 선택한 이미지 \(selectedImages.count)개를 업로드합니다.")
                    files = try await uploadImages(selectedImages)
                    print("✅ 업로드된 이미지 URLs: \(files)")
                } else {
                    print("⚠️ 선택된 이미지가 없습니다.")
                }

                print("🚀 모임 생성 요청 - files: \(files)")

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

                print("✅ 모임 생성 응답 - files: \(response.files)")

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

    private func uploadImages(_ images: [UIImage]) async throws -> [String] {
        // 모든 이미지를 Data로 변환
        var imageDatas: [Data] = []
        for image in images {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("❌ Failed to convert image to JPEG data")
                continue
            }
            imageDatas.append(imageData)
        }

        guard !imageDatas.isEmpty else {
            print("❌ No valid images to upload")
            return []
        }

        // 모든 이미지를 한 번에 업로드
        let fileDTO = try await networkService.upload(
            PostRouter.uploadFiles(images: imageDatas),
            images: imageDatas,
            responseType: FileDTO.self
        )

        print("✅ Images uploaded successfully: \(fileDTO.files)")
        return fileDTO.files
    }

    // MARK: - Edit Functions

    private func loadMeetForEdit(postId: String) {
        state.isLoadingMeetForEdit = true
        state.loadMeetErrorMessage = nil

        Task {
            do {
                print("🔄 Loading meet for edit: \(postId)")

                let postData = try await networkService.request(
                    PostRouter.fetchPost(postId: postId),
                    responseType: PostDTO.self
                )

                let meetDetail = MeetDetail(
                    postId: postData.postId,
                    title: postData.title,
                    content: postData.content,
                    creator: MeetDetail.Creator(
                        userId: postData.creator.userId,
                        nickname: postData.creator.nick,
                        profileImage: postData.creator.profileImage
                    ),
                    date: formatDate(postData.value5 ?? postData.createdAt),
                    location: extractLocationFromContent(postData.content),
                    address: postData.content,
                    price: formatPrice(postData.value3),
                    capacity: Int(postData.value1 ?? "0") ?? 0,
                    currentParticipants: postData.buyers.count,
                    participants: postData.buyers.map { buyer in
                        MeetDetail.Participant(
                            userId: buyer.userId,
                            nickname: buyer.nick,
                            profileImage: buyer.profileImage
                        )
                    },
                    imageNames: postData.files,
                    daysLeft: calculateDaysLeft(postData.value5 ?? postData.createdAt),
                    gender: postData.value2 ?? "누구나",
                    spaceInfo: postData.value4 != nil ? MeetDetail.SpaceInfo(
                        spaceId: postData.value4!,
                        title: extractLocationFromContent(postData.content),
                        address: postData.content
                    ) : nil
                )

                await MainActor.run {
                    state.originalMeetData = meetDetail
                    state.isLoadingMeetForEdit = false
                    // 기존 이미지 URL 설정
                    existingImageURLs = meetDetail.imageNames
                    shouldKeepExistingImages = true
                    // 새로 선택한 이미지는 초기화
                    selectedImages = []
                    selectedPhotoItems = []
                    print("✅ Meet data loaded for edit: \(meetDetail.title)")
                    print("📸 기존 이미지 \(existingImageURLs.count)개 로드됨")
                }

            } catch {
                print("❌ Error loading meet for edit: \(error)")
                await MainActor.run {
                    state.loadMeetErrorMessage = error.localizedDescription
                    state.isLoadingMeetForEdit = false
                }
            }
        }
    }

    private func updateMeet(postId: String, title: String, description: String, capacity: Int, price: String, gender: String, selectedSpace: Space?, startDate: Date) {
        state.isUpdatingMeet = true
        state.updateMeetErrorMessage = nil

        Task {
            do {
                print("🔄 Updating meet: \(postId)")

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

                // 이미지 처리 로직
                var files: [String] = []

                if !selectedImages.isEmpty {
                    // 사용자가 새로운 이미지를 선택한 경우 업로드
                    print("📸 새로운 이미지 \(selectedImages.count)개를 업로드합니다.")
                    files = try await uploadImages(selectedImages)
                } else if shouldKeepExistingImages {
                    // 기존 이미지 유지
                    files = existingImageURLs
                    print("📸 기존 이미지 \(files.count)개를 유지합니다.")
                } else {
                    // 이미지 없음
                    files = []
                    print("📸 이미지를 모두 제거합니다.")
                }

                // 모임 업데이트 API 호출
                let response = try await networkService.request(
                    PostRouter.updatePost(
                        postId: postId,
                        title: title,
                        content: fullDescription,
                        files: files,
                        additionalFields: additionalFields
                    ),
                    responseType: PostDTO.self
                )

                print("✅ Meet updated successfully: \(response.postId)")

                await MainActor.run {
                    state.isUpdatingMeet = false
                    state.isMeetUpdated = true
                }

            } catch {
                print("❌ Error updating meet: \(error)")
                await MainActor.run {
                    state.updateMeetErrorMessage = error.localizedDescription
                    state.isUpdatingMeet = false
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func extractLocationFromContent(_ content: String) -> String {
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

    private func deleteMeet(postId: String) {
        state.isDeletingMeet = true
        state.deleteMeetErrorMessage = nil

        Task {
            do {
                print("🔄 Deleting meet: \(postId)")

                // 모임 삭제 API 호출 (응답 데이터 없음)
                try await networkService.request(PostRouter.deletePost(postId: postId))

                print("✅ Meet deleted successfully: \(postId)")

                await MainActor.run {
                    state.isDeletingMeet = false
                    state.isMeetDeleted = true
                }

            } catch {
                print("❌ Error deleting meet: \(error)")
                await MainActor.run {
                    state.deleteMeetErrorMessage = error.localizedDescription
                    state.isDeletingMeet = false
                }
            }
        }
    }
}
