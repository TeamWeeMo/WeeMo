//
//  SpaceCreateStore.swift
//  WeeMo
//
//  Created by Reimos on 11/16/25.
//

import Foundation
import Combine
import UIKit

// MARK: - Space Create Store

final class SpaceCreateStore: ObservableObject {
    @Published private(set) var state = SpaceCreateState()

    private let networkService: NetworkService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer

    init(networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Intent Handler

    func send(_ intent: SpaceCreateIntent) {
        switch intent {
        case .titleChanged(let title):
            state.title = title

        case .priceChanged(let price):
            state.price = price

        case .addressChanged(let address):
            state.address = address

        case .ratingChanged(let rating):
            // 0.5 단위로 반올림
            let roundedRating = (rating * 2).rounded() / 2
            state.rating = roundedRating

        case .descriptionChanged(let description):
            state.description = description

        case .categoryChanged(let category):
            state.category = category

        case .popularToggled(let isPopular):
            state.isPopular = isPopular

        case .hashTagInputChanged(let input):
            state.hashTagInput = input

        case .addHashTag:
            handleAddHashTag()

        case .removeHashTag(let tag):
            handleRemoveHashTag(tag)

        case .imageSelected(let image):
            state.selectedImage = image

        case .imageRemoved:
            state.selectedImage = nil

        case .submitButtonTapped:
            handleSubmit()

        case .resetForm:
            handleReset()
        }
    }

    // MARK: - Private Handlers

    private func handleAddHashTag() {
        let trimmedTag = state.hashTagInput.trimmingCharacters(in: .whitespaces)

        guard state.canAddHashTag else { return }

        state.hashTags.append(trimmedTag)
        state.hashTagInput = ""
    }

    private func handleRemoveHashTag(_ tag: String) {
        state.hashTags.removeAll { $0 == tag }
    }

    private func handleSubmit() {
        // 유효성 검사
        guard state.isSubmitEnabled else {
            state.errorMessage = "모든 필수 항목을 입력해주세요."
            return
        }

        guard state.isValidPrice else {
            state.errorMessage = "올바른 가격을 입력해주세요."
            return
        }

        guard let selectedImage = state.selectedImage else {
            state.errorMessage = "이미지를 선택해주세요."
            return
        }

        state.isLoading = true
        state.errorMessage = nil

        Task {
            do {
                // 1: 이미지 업로드
                print("[SpaceCreateStore] 이미지 업로드 시작")
                let uploadedFilePaths = try await uploadImage(selectedImage)

                guard let filePath = uploadedFilePaths.first else {
                    throw NetworkError.noData
                }
                print("[SpaceCreateStore] 이미지 업로드 성공: \(filePath)")

                // 2: 게시글 생성
                print("[SpaceCreateStore] 게시글 생성 시작")
                try await createSpacePost(filePath: filePath)

                await MainActor.run {
                    state.isLoading = false
                    state.isSubmitSuccessful = true
                    print("[SpaceCreateStore] 공간 등록 완료!")
                }
            } catch {
                await MainActor.run {
                    state.isLoading = false
                    state.errorMessage = "등록 실패: \(error.localizedDescription)"
                    print("[SpaceCreateStore] 에러: \(error)")
                }
            }
        }
    }

    private func handleReset() {
        state = SpaceCreateState()
    }

    // MARK: - Network Methods

    /// 이미지 업로드
    private func uploadImage(_ image: UIImage) async throws -> [String] {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NetworkError.badRequest("이미지를 처리할 수 없습니다.")
        }

        let fileDTO = try await networkService.upload(
            PostRouter.uploadFiles(images: [imageData]),
            images: [imageData],
            responseType: FileDTO.self
        )

        return fileDTO.files
    }

    /// 공간 게시글 생성
    private func createSpacePost(filePath: String) async throws {
        // additionalFields: value1~value5, geolocation 매핑
        // value1: 주소
        // value2: 평점
        // value3: 인기 공간 여부
        // value4: 편의시설 (현재는 빈 문자열)
        // value5: 주차 가능 여부 (현재는 false)

        guard let priceInt = Int(state.price) else {
            throw NetworkError.badRequest("올바른 가격을 입력해주세요.")
        }

        // content에 해시태그 추가
        var contentWithHashTags = state.description
        if !state.hashTags.isEmpty {
            let hashTagString = state.hashTags.map { "#\($0)" }.joined(separator: " ")
            contentWithHashTags += " \(hashTagString)"
        }

        // SpaceRouter 사용 (longitude, latitude를 Number로 전송)
        _ = try await networkService.request(
            SpaceRouter.createSpace(
                title: state.title,
                price: priceInt,
                content: contentWithHashTags,
                files: [filePath],
                value1: state.address,
                value2: String(format: "%.1f", state.rating),
                value3: state.isPopular ? "true" : "false",
               // value4: "",  // 편의시설 (현재 미사용)
               // value5: "false",  // 주차 가능 여부 (현재 미사용)
                longitude: 126.9244,
                latitude: 37.5600
            ),
            responseType: PostDTO.self
        )
    }
}
