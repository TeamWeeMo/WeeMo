//
//  SpaceCreateStore.swift
//  WeeMo
//
//  Created by Reimos on 11/16/25.
//

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

        case .addressSelected(let address, let roadAddress, let latitude, let longitude):
            state.address = address
            state.roadAddress = roadAddress
            state.latitude = latitude
            state.longitude = longitude

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

        case .parkingToggled(let hasParking):
            state.hasParking = hasParking

        case .restroomToggled(let hasRestroom):
            state.hasRestroom = hasRestroom

        case .maxCapacityChanged(let capacity):
            state.maxCapacity = capacity

        case .hashTagInputChanged(let input):
            state.hashTagInput = input

        case .addHashTag:
            handleAddHashTag()

        case .removeHashTag(let tag):
            handleRemoveHashTag(tag)

        case .mediaItemsSelected(let mediaItems):
            handleMediaItemsSelected(mediaItems)

        case .mediaItemRemoved(let index):
            handleMediaItemRemoved(at: index)

        case .imageSelected(let image):
            handleImageSelected(image)

        case .imageRemoved(let index):
            handleImageRemoved(at: index)

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

    private func handleImageSelected(_ image: UIImage) {
        guard state.canAddMoreImages else {
            state.errorMessage = "최대 \(SpaceCreateState.maxImageCount)개까지만 추가할 수 있습니다."
            return
        }
        state.selectedImages.append(image)
        state.errorMessage = nil
    }

    private func handleImageRemoved(at index: Int) {
        guard index < state.selectedImages.count else { return }
        state.selectedImages.remove(at: index)
    }

    // MARK: - Media Handlers

    private func handleMediaItemsSelected(_ mediaItems: [MediaItem]) {
        // 최대 개수 확인
        let remainingSlots = SpaceCreateState.maxMediaCount - state.selectedMediaItems.count
        let itemsToAdd = Array(mediaItems.prefix(remainingSlots))

        if itemsToAdd.count < mediaItems.count {
            state.errorMessage = "최대 \(SpaceCreateState.maxMediaCount)개까지만 추가할 수 있습니다."
        }

        state.selectedMediaItems.append(contentsOf: itemsToAdd)
        print("[SpaceCreateStore] 미디어 \(itemsToAdd.count)개 추가 완료 (총 \(state.selectedMediaItems.count)개)")
    }

    private func handleMediaItemRemoved(at index: Int) {
        guard index < state.selectedMediaItems.count else { return }
        let removedItem = state.selectedMediaItems[index]
        state.selectedMediaItems.remove(at: index)
        print("[SpaceCreateStore] 미디어 삭제: \(removedItem.type == .image ? "이미지" : "동영상")")
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

        guard !state.selectedMediaItems.isEmpty else {
            state.errorMessage = "이미지 또는 동영상을 선택해주세요."
            return
        }

        state.isLoading = true
        state.errorMessage = nil

        Task {
            do {
                // 1: 미디어 업로드 (이미지 + 동영상)
                print("[SpaceCreateStore] 미디어 \(state.selectedMediaItems.count)개 업로드 시작")
                let uploadedFilePaths = try await uploadMediaItems(state.selectedMediaItems)

                print("[SpaceCreateStore] 미디어 업로드 성공: \(uploadedFilePaths)")

                // 2: 게시글 생성
                print("[SpaceCreateStore] 게시글 생성 시작")
                try await createSpacePost(filePaths: uploadedFilePaths)

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

    /// 미디어 업로드 (이미지 + 동영상) - multipartUpload 사용
    private func uploadMediaItems(_ mediaItems: [MediaItem]) async throws -> [String] {
        // MediaItem -> (Data, fileName, mimeType) 튜플 배열로 변환
        let files: [(data: Data, fileName: String, mimeType: String)] = mediaItems.enumerated().map { index, item in
            let fileName = item.originalFileName ?? "file_\(index).\(item.fileExtension)"
            return (data: item.data, fileName: fileName, mimeType: item.mimeType)
        }

        let fileDTO = try await networkService.multipartUpload(
            PostRouter.uploadFiles(images: []),
            files: files,
            responseType: FileDTO.self
        )

        return fileDTO.files
    }

    /// 이미지 업로드 (하위 호환성)
    private func uploadImages(_ images: [UIImage]) async throws -> [String] {
        // UIImage -> Data 변환
        let imageDatas = try images.map { image -> Data in
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw NetworkError.badRequest("이미지를 처리할 수 없습니다.")
            }
            return imageData
        }

        let fileDTO = try await networkService.upload(
            PostRouter.uploadFiles(images: imageDatas),
            images: imageDatas,
            responseType: FileDTO.self
        )

        return fileDTO.files
    }

    /// 공간 게시글 생성
    private func createSpacePost(filePaths: [String]) async throws {
        // value1: 주소
        // value2: 카테고리
        // value3: 평점
        // value4: 시간당 가격
        // value5: 인기 공간 여부 ("true" or "false")
        // value6: 주차 ("true" or "false")
        // value7: 화장실 여부 ("true" or "false")
        // value8: 최대인원 ("6")
        // value9: 도로명 주소

        guard let priceInt = Int(state.price) else {
            throw NetworkError.badRequest("올바른 가격을 입력해주세요.")
        }

        // content에 해시태그 추가
        var contentWithHashTags = state.description
        if !state.hashTags.isEmpty {
            let hashTagString = state.hashTags.map { "#\($0)" }.joined(separator: " ")
            contentWithHashTags += " \(hashTagString)"
        }

        // additionalFields 구성
        var additionalFields: [String: String] = [
            "value1": state.address,
            "value2": state.category.rawValue,
            "value3": String(format: "%.1f", state.rating),
            "value4": state.price,
            "value5": state.isPopular ? "true" : "false",
            "value6": state.hasParking ? "true" : "false",
            "value7": state.hasRestroom ? "true" : "false",
        ]

        // 최대인원 추가 (입력된 경우만)
        if !state.maxCapacity.isEmpty {
            additionalFields["value8"] = state.maxCapacity
        }

        // 도로명 주소 추가 (있는 경우만)
        if !state.roadAddress.isEmpty {
            additionalFields["value9"] = state.roadAddress
        }

        // PostRouter 사용 (사용자가 선택한 실제 좌표 전송)
        _ = try await networkService.request(
            PostRouter.createPost(
                title: state.title,
                price: priceInt,
                content: contentWithHashTags,
                category: .space,
                files: filePaths,
                additionalFields: additionalFields,
                latitude: state.latitude,
                longitude: state.longitude
            )
        )
    }

}
