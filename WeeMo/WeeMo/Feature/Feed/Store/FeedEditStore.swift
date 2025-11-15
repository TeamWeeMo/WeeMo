//
//  FeedEditStore.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation
import Combine
import UIKit

// MARK: - Feed Edit Store

@Observable
final class FeedEditStore {
    // MARK: - Properties

    private(set) var state = FeedEditState()

    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // 임시 토큰 (로그인 기능 완성 전까지 사용)
    private let temporaryToken: String

    // MARK: - Initializer

    init(
        networkService: NetworkServiceProtocol,
        temporaryToken: String = ""
    ) {
        self.networkService = networkService
        self.temporaryToken = temporaryToken

        // 임시 토큰을 UserDefaults에 저장 (APIRouter에서 사용)
        if !temporaryToken.isEmpty {
            UserDefaults.standard.set(temporaryToken, forKey: "accessToken")
        }
    }

    // MARK: - Intent Handler

    func send(_ intent: FeedEditIntent) {
        switch intent {
        case .onAppear:
            handleOnAppear()

        case .updateContent(let content):
            state.content = content

        case .selectImages(let images):
            state.selectedImages = images

        case .removeImage(let index):
            state.selectedImages.remove(at: index)

        case .submitPost:
            Task {
                await submitPost()
            }

        case .cancel:
            // 취소는 View에서 dismiss 처리
            break

        case .uploadImagesSuccess(let filePaths):
            handleUploadImagesSuccess(filePaths)

        case .uploadImagesFailed(let error):
            handleUploadImagesFailed(error)

        case .createPostSuccess(let feed):
            handleCreatePostSuccess(feed)

        case .createPostFailed(let error):
            handleCreatePostFailed(error)
        }
    }

    // MARK: - Private Methods

    private func handleOnAppear() {
        // 초기화 작업 (필요 시)
    }

    private func submitPost() async {
        guard state.canSubmit else { return }

        // 1. 로딩 시작
        await MainActor.run {
            state.isUploading = true
            state.errorMessage = nil
        }

        do {
            // 2. 이미지 압축 및 검증 (최대 10MB, 최대 5장)
            let imageDatas = ImageCompressor.compress(state.selectedImages, maxSizeInMB: 10, maxDimension: 2048)

            // 최대 5장 제한 체크
            guard imageDatas.count <= 5 else {
                throw NSError(
                    domain: "FeedEditStore",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "이미지는 최대 5장까지 업로드 가능합니다."]
                )
            }

            // 3. 이미지 업로드
            let uploadResponse = try await networkService.upload(
                PostRouter.uploadFiles(images: imageDatas),
                images: imageDatas,
                responseType: FileDTO.self
            )

            // 3. 게시글 생성
            let postResponse = try await networkService.request(
                PostRouter.createPost(
                    title: "",  // 피드는 제목 없음
                    content: state.content,
                    category: .feed,
                    files: uploadResponse.files,
                    additionalFields: nil
                ),
                responseType: PostDTO.self
            )

            // 4. DTO → Domain Model 변환
            let feed = postResponse.toFeed()

            // 5. 성공 처리
            await MainActor.run {
                state.isUploading = false
                state.isSubmitted = true
                state.createdFeed = feed
            }

        } catch {
            // 에러 처리
            await MainActor.run {
                state.isUploading = false
                state.errorMessage = (error as? NetworkError)?.localizedDescription ?? "게시글 작성에 실패했습니다."
            }
        }
    }

    private func handleUploadImagesSuccess(_ filePaths: [String]) {
        // Combine 방식을 사용할 경우
    }

    private func handleUploadImagesFailed(_ error: Error) {
        state.isUploading = false
        state.errorMessage = "이미지 업로드에 실패했습니다."
    }

    private func handleCreatePostSuccess(_ feed: Feed) {
        state.isUploading = false
        state.isSubmitted = true
        state.createdFeed = feed
    }

    private func handleCreatePostFailed(_ error: Error) {
        state.isUploading = false
        state.errorMessage = (error as? NetworkError)?.localizedDescription ?? "게시글 작성에 실패했습니다."
    }
}

// MARK: - Combine 방식 (선택사항)

extension FeedEditStore {
    /// Combine Publisher 방식으로 게시글 작성
    func submitPostWithPublisher() {
        guard state.canSubmit else { return }

        state.isUploading = true
        state.errorMessage = nil

        let imageDatas = state.selectedImages.compactMap { $0.jpegData(compressionQuality: 0.8) }

        // 1. 이미지 업로드
        networkService.requestPublisher(
            PostRouter.uploadFiles(images: imageDatas),
            responseType: FileDTO.self
        )
        .flatMap { [weak self] uploadResponse -> AnyPublisher<PostDTO, NetworkError> in
            guard let self = self else {
                return Fail(error: .unknown(NSError(domain: "Store", code: -1)))
                    .eraseToAnyPublisher()
            }

            // 2. 게시글 생성
            return self.networkService.requestPublisher(
                PostRouter.createPost(
                    title: "",
                    content: self.state.content,
                    category: .feed,
                    files: uploadResponse.files,
                    additionalFields: nil
                ),
                responseType: PostDTO.self
            )
        }
        .map { $0.toFeed() }  // DTO → Domain
        .receive(on: DispatchQueue.main)  // MainActor로 전환
        .sink { [weak self] completion in
            if case .failure(let error) = completion {
                self?.send(.createPostFailed(error))
            }
        } receiveValue: { [weak self] feed in
            self?.send(.createPostSuccess(feed))
        }
        .store(in: &cancellables)
    }
}
