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

    init(mode: SpaceCreateState.Mode = .create, networkService: NetworkService = NetworkService()) {
        self.networkService = networkService
        self.state.mode = mode

        // 수정 모드인 경우 기존 데이터 로드
        if case .edit(let postId) = mode {
            self.state.postId = postId
            loadExistingPost(postId: postId)
        }
    }

    // MARK: - Load Existing Post

    private func loadExistingPost(postId: String) {
        Task {
            do {
                await MainActor.run {
                    state.isLoading = true
                }

                let postDTO = try await networkService.request(
                    PostRouter.fetchPost(postId: postId),
                    responseType: PostDTO.self
                )

                await MainActor.run {
                    // PostDTO -> State로 변환
                    state.title = postDTO.title
                    state.price = postDTO.value4 ?? ""
                    state.address = postDTO.value1 ?? ""
                    state.roadAddress = postDTO.value9 ?? ""
                    state.latitude = postDTO.geolocation.latitude
                    state.longitude = postDTO.geolocation.longitude
                    state.rating = Double(postDTO.value3 ?? "3.0") ?? 3.0
                    state.description = postDTO.content

                    // 카테고리
                    state.category = parseSpaceCategory(from: postDTO.value2)

                    // 인기 공간
                    state.isPopular = postDTO.value5 == "true"

                    // 편의시설
                    state.hasParking = postDTO.value6 == "true"
                    state.hasRestroom = postDTO.value7 == "true"
                    state.maxCapacity = postDTO.value8 ?? ""

                    // 해시태그 (content에서 추출)
                    state.hashTags = extractHashTags(from: postDTO.content)

                    // 기존 파일 URL (상대 경로를 전체 URL로 변환)
                    state.existingFileURLs = postDTO.files.map { fileURL in
                        if fileURL.hasPrefix("http") {
                            return fileURL
                        } else {
                            return NetworkConstants.baseURL + fileURL
                        }
                    }

                    print("[SpaceCreateStore] 기존 게시글 로드 완료: \(postDTO.title)")
                    print("[SpaceCreateStore] 기존 파일 URL: \(state.existingFileURLs)")

                    state.isLoading = false
                }
            } catch {
                await MainActor.run {
                    state.isLoading = false
                    state.errorMessage = "게시글을 불러올 수 없습니다."
                    print("[SpaceCreateStore] 게시글 로드 실패: \(error)")
                }
            }
        }
    }

    private func parseSpaceCategory(from categoryString: String?) -> SpaceCategory {
        switch categoryString {
        case "파티룸": return .party
        case "스터디룸": return .studyRoom
        case "스튜디오": return .studio
        case "연습실": return .practice
        case "회의실": return .meetingRoom
        case "카페": return .cafe
        default: return .all
        }
    }

    private func extractHashTags(from content: String) -> [String] {
        let words = content.components(separatedBy: " ")
        return words.filter { $0.hasPrefix("#") }.map { String($0.dropFirst()) }
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

        case .analyzeImagesForHashTags:
            handleAnalyzeImages()

        case .addSuggestedHashTag(let tag):
            handleAddSuggestedHashTag(tag)

        case .mediaItemsSelected(let mediaItems):
            handleMediaItemsSelected(mediaItems)

        case .mediaItemRemoved(let index):
            handleMediaItemRemoved(at: index)

        case .existingFileRemoved(let index):
            handleExistingFileRemoved(at: index)

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

    // MARK: - AI Hash Tag Handlers

    /// AI 이미지 분석 (Vision Framework)
    private func handleAnalyzeImages() {
        // 이미 분석 중이면 무시
        guard !state.isAnalyzingImage else { return }

        state.isAnalyzingImage = true
        state.errorMessage = nil

        Task {
            var imageToAnalyze: UIImage?

            // 1. 새로 선택한 미디어 아이템이 있으면 우선 사용
            if let firstMediaItem = state.selectedMediaItems.first {
                imageToAnalyze = firstMediaItem.thumbnail
            }
            // 2. 수정 모드: 기존 파일 URL에서 이미지 다운로드
            else if let firstFileURL = state.existingFileURLs.first {
                imageToAnalyze = await downloadImage(from: firstFileURL)
            }

            // 이미지가 없으면 에러
            guard let finalImage = imageToAnalyze else {
                await MainActor.run {
                    state.isAnalyzingImage = false
                    state.errorMessage = "분석할 이미지를 불러올 수 없습니다."
                }
                return
            }

            print("[SpaceCreateStore] AI 해시태그 분석 시작")

            // VisionService로 이미지 분석
            let tags = await VisionService.shared.analyzeImageForHashTags(
                finalImage,
                maxResults: 10,
                minConfidence: 0.3
            )

            await MainActor.run {
                // 중복 제거: 이미 추가된 해시태그 제외
                let newTags = tags.filter { !state.hashTags.contains($0) }

                state.suggestedHashTags = newTags
                state.isAnalyzingImage = false

                print("[SpaceCreateStore] AI 해시태그 분석 완료: \(newTags)")

                if newTags.isEmpty {
                    state.errorMessage = "이미지에서 해시태그를 추출할 수 없습니다."
                }
            }
        }
    }

    /// URL에서 이미지 다운로드 (수정 모드용)
    private func downloadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("[SpaceCreateStore] 이미지 다운로드 실패: \(error.localizedDescription)")
            return nil
        }
    }

    /// AI 제안 해시태그 추가
    private func handleAddSuggestedHashTag(_ tag: String) {
        // 이미 추가된 태그는 무시
        guard !state.hashTags.contains(tag) else {
            print("[SpaceCreateStore] 이미 추가된 해시태그: \(tag)")
            return
        }

        state.hashTags.append(tag)
        print("[SpaceCreateStore] AI 제안 해시태그 추가: \(tag)")
    }

    private func handleImageSelected(_ image: UIImage) {
        guard state.canAddMoreImages else {
            state.errorMessage = "최대 \(SpaceCreateState.maxImageCount)개까지만 추가할 수 있습니다."
            return
        }
        state.selectedImages.append(image)
        state.errorMessage = nil
    }

    private func handleExistingFileRemoved(at index: Int) {
        guard index < state.existingFileURLs.count else { return }
        state.existingFileURLs.remove(at: index)
        print("[SpaceCreateStore] 기존 파일 삭제: 인덱스 \(index)")
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

        // 수정 모드: 기존 파일이 있거나 새 미디어가 있어야 함
        // 생성 모드: 새 미디어가 필수
        if case .create = state.mode {
            guard !state.selectedMediaItems.isEmpty else {
                state.errorMessage = "이미지 또는 동영상을 선택해주세요."
                return
            }
        }

        state.isLoading = true
        state.errorMessage = nil

        Task {
            do {
                // 모드에 따라 분기
                switch state.mode {
                case .create:
                    try await createSpace()
                case .edit(let postId):
                    try await updateSpace(postId: postId)
                }

                await MainActor.run {
                    state.isLoading = false
                    state.isSubmitSuccessful = true
                }
            } catch {
                await MainActor.run {
                    state.isLoading = false
                    state.errorMessage = "처리 실패: \(error.localizedDescription)"
                    print("[SpaceCreateStore] 에러: \(error)")
                }
            }
        }
    }

    // MARK: - Create/Update Space

    /// 공간 생성
    private func createSpace() async throws {
        // 1: 미디어 업로드 (이미지 + 동영상)
        print("[SpaceCreateStore] 미디어 \(state.selectedMediaItems.count)개 업로드 시작")
        let uploadedFilePaths = try await uploadMediaItems(state.selectedMediaItems)

        print("[SpaceCreateStore] 미디어 업로드 성공: \(uploadedFilePaths)")

        // 2: 게시글 생성
        print("[SpaceCreateStore] 게시글 생성 시작")
        try await createSpacePost(filePaths: uploadedFilePaths)

        print("[SpaceCreateStore] 공간 등록 완료!")
    }

    /// 공간 수정
    private func updateSpace(postId: String) async throws {
        // 1: 기존 파일 경로 (전체 URL -> 상대 경로로 변환)
        var filePaths = state.existingFileURLs.map { urlString -> String in
            if urlString.hasPrefix(NetworkConstants.baseURL) {
                // 베이스 URL 제거하고 상대 경로만 반환
                return String(urlString.dropFirst(NetworkConstants.baseURL.count))
            } else {
                // 이미 상대 경로면 그대로 반환
                return urlString
            }
        }

        // 2: 새 미디어가 있으면 업로드
        if !state.selectedMediaItems.isEmpty {
            print("[SpaceCreateStore] 새 미디어 \(state.selectedMediaItems.count)개 업로드 시작")
            let uploadedFilePaths = try await uploadMediaItems(state.selectedMediaItems)
            filePaths.append(contentsOf: uploadedFilePaths)
            print("[SpaceCreateStore] 미디어 업로드 성공")
        }

        // 3: 게시글 수정
        print("[SpaceCreateStore] 게시글 수정 시작")
        print("[SpaceCreateStore] 전송할 파일 경로: \(filePaths)")
        try await updateSpacePost(postId: postId, filePaths: filePaths)

        print("[SpaceCreateStore] 공간 수정 완료!")
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

    /// 공간 게시글 수정
    private func updateSpacePost(postId: String, filePaths: [String]) async throws {
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

        // PostRouter.updatePost 사용
        _ = try await networkService.request(
            PostRouter.updatePost(
                postId: postId,
                title: state.title,
                content: contentWithHashTags,
                files: filePaths,
                additionalFields: additionalFields
            )
        )
    }

}
