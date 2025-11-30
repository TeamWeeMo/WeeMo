//
//  MeetEditStore.swift
//  WeeMo
//
//  Created by 차지용 on 11/14/25.
//

import Foundation
import SwiftUI
import Combine
import UIKit
import PhotosUI

// MARK: - Meet Edit Store

@Observable
final class MeetEditStore {
    // MARK: - Properties

    private(set) var state = MeetEditState()

    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Intent Handler

    func send(_ intent: MeetEditIntent) {
        switch intent {
        // MARK: - Lifecycle
        case .onAppear:
            handleOnAppear()

        case .loadMeetForEdit(let postId):
            Task { await loadMeetForEdit(postId: postId) }

        // MARK: - Form Updates
        case .updateTitle(let title):
            state.title = title

        case .updateContent(let content):
            state.content = content

        case .updateCapacity(let capacity):
            state.capacity = max(1, capacity)
            state.pricePerPerson = state.calculatedPrice

        case .updateGender(let gender):
            state.gender = gender

        case .updateRecruitmentStartDate(let date):
            state.recruitmentStartDate = date

        case .updateRecruitmentEndDate(let date):
            state.recruitmentEndDate = date

        case .updateMeetingStartDate(let date):
            state.meetingStartDate = date

        case .updateMeetingEndDate(let date):
            state.meetingEndDate = date

        case .updateTotalHours(let hours):
            state.totalHours = max(1, hours)
            state.pricePerPerson = state.calculatedPrice

        // MARK: - Media (Image + Video)
        case .selectMediaItems(let items):
            state.selectedMediaItems = items
            if !items.isEmpty {
                state.shouldKeepExistingMedia = false
            }

        case .removeMediaItem(let index):
            if index < state.selectedMediaItems.count {
                state.selectedMediaItems.remove(at: index)
            }

        case .removeExistingMedia(let index):
            if index < state.existingMediaURLs.count {
                state.existingMediaURLs.remove(at: index)
                if state.existingMediaURLs.isEmpty {
                    state.shouldKeepExistingMedia = false
                }
            }

        case .loadMediaFromPhotos(let items):
            Task { await loadMediaFromPhotos(items) }

        case .handleSelectedImages(let images):
            Task { await handleSelectedImages(images) }

        case .autoCompressVideo(let url):
            Task { await autoCompressVideo(url) }

        case .setVideoCompressionFailed:
            state.videoCompressionFailed = true

        case .resetVideoCompressionFailed:
            state.videoCompressionFailed = false

        // MARK: - Space Selection
        case .loadSpaces:
            Task { await loadSpaces() }

        case .selectSpace(let space):
            // 이미 선택된 공간을 다시 탭하면 선택 해제 (토글)
            if state.selectedSpace?.id == space.id {
                state.selectedSpace = nil
            } else {
                state.selectedSpace = space
            }

        case .confirmSpaceSelection:
            // 완료 버튼 클릭 시 선택한 공간의 예약 정보를 댓글에서 로드
            if let space = state.selectedSpace {
                Task { await loadReservationInfo(for: space.id) }
            }

        // MARK: - Submit
        case .createMeet:
            Task { await createMeet() }

        case .updateMeet(let postId):
            Task { await updateMeet(postId: postId) }

        // MARK: - Navigation
        case .cancel:
            break

        // MARK: - Alert
        case .showErrorAlert:
            state.showErrorAlert = true

        case .dismissErrorAlert:
            state.showErrorAlert = false
            state.errorMessage = nil

        case .showSuccessAlert:
            state.showSuccessAlert = true

        case .dismissSuccessAlert:
            state.showSuccessAlert = false

        // MARK: - Payment
        case .showPaymentRequiredAlert:
            state.showPaymentRequiredAlert = true

        case .dismissPaymentRequiredAlert:
            state.showPaymentRequiredAlert = false

        case .confirmPayment:
            state.showPaymentRequiredAlert = false
            state.shouldNavigateToPayment = true

        case .clearPaymentNavigation:
            state.shouldNavigateToPayment = false

        case .validatePayment(let impUid, let postId):
            Task { await validatePayment(impUid: impUid, postId: postId) }

        case .dismissPaymentSuccess:
            state.paymentSuccessMessage = nil
        }
    }

    // MARK: - Private Methods

    private func handleOnAppear() {
        if state.spaces.isEmpty {
            Task { await loadSpaces() }
        }
    }

    // MARK: - Load Spaces

    private func loadSpaces() async {
        await MainActor.run {
            state.isLoadingSpaces = true
            state.spacesErrorMessage = nil
        }

        do {
            let response = try await networkService.request(
                PostRouter.fetchMyLikedPosts(next: nil, limit: 20, category: .space),
                responseType: PostListDTO.self
            )

            let spaces = response.data.map { $0.toSpace() }

            await MainActor.run {
                state.spaces = spaces
                state.isLoadingSpaces = false
            }
        } catch {
            await MainActor.run {
                state.isLoadingSpaces = false
                state.spacesErrorMessage = (error as? NetworkError)?.localizedDescription ?? "공간을 불러오는데 실패했습니다."
            }
        }
    }

    // MARK: - Load Meet for Edit

    private func loadMeetForEdit(postId: String) async {
        await MainActor.run {
            state.isLoadingForEdit = true
            state.errorMessage = nil
        }

        do {
            let postDTO = try await networkService.request(
                PostRouter.fetchPost(postId: postId),
                responseType: PostDTO.self
            )

            let meet = postDTO.toMeet()

            await MainActor.run {
                state.originalMeet = meet
                populateFormFromMeet(meet)
                state.isLoadingForEdit = false
            }

            // 공간 정보 불러오기
            if let spaceId = meet.spaceId {
                await loadSpaceForEdit(spaceId: spaceId)
            }
        } catch {
            await MainActor.run {
                state.errorMessage = (error as? NetworkError)?.localizedDescription ?? "모임 정보를 불러오는데 실패했습니다."
                state.isLoadingForEdit = false
            }
        }
    }

    private func populateFormFromMeet(_ meet: Meet) {
        state.title = meet.title
        state.content = meet.content
        state.capacity = meet.capacity
        state.gender = meet.gender
        state.recruitmentStartDate = meet.recruitmentStartDate
        state.recruitmentEndDate = meet.recruitmentEndDate
        state.meetingStartDate = meet.meetingStartDate
        state.meetingEndDate = meet.meetingEndDate
        state.totalHours = meet.totalHours
        state.pricePerPerson = meet.pricePerPerson
        state.existingMediaURLs = meet.fileURLs
        state.shouldKeepExistingMedia = true

        // 예약 정보 파싱 (reservationInfo: "yyyyMMddHHmm,totalHours")
        if let parsed = ReservationFormatter.parseReservationISO("#\(meet.reservationInfo)") {
            state.reservationDate = parsed.date
            state.reservationStartHour = parsed.startHour
            state.reservationTotalHours = parsed.totalHours
        }
    }

    /// 수정 모드에서 공간 정보 불러오기
    private func loadSpaceForEdit(spaceId: String) async {
        do {
            let postDTO = try await networkService.request(
                PostRouter.fetchPost(postId: spaceId),
                responseType: PostDTO.self
            )

            let space = postDTO.toSpace()

            await MainActor.run {
                state.selectedSpace = space
            }
        } catch {
            // 공간 불러오기 실패는 조용히 처리 (나머지 정보는 정상적으로 로드됨)
            print("[MeetEditStore] 공간 불러오기 실패: \(error)")
        }
    }

    // MARK: - Create Meet

    private func createMeet() async {
        guard state.isFormValid else {
            await MainActor.run {
                state.errorMessage = "모든 필드를 입력해주세요."
                state.showErrorAlert = true
            }
            return
        }

        await MainActor.run {
            state.isCreating = true
            state.errorMessage = nil
        }

        do {
            // 미디어 업로드 (이미지 + 동영상)
            var files: [String] = []
            if !state.selectedMediaItems.isEmpty {
                files = try await uploadMedia(state.selectedMediaItems)
            }

            // additionalFields 구성
            let additionalFields = buildAdditionalFields()

            // API 호출
            let response = try await networkService.request(
                PostRouter.createPost(
                    title: state.title,
                    price: state.pricePerPerson,
                    content: state.content,
                    category: .meet,
                    files: files,
                    additionalFields: additionalFields,
                    latitude: state.selectedSpace?.latitude,
                    longitude: state.selectedSpace?.longitude
                ),
                responseType: PostDTO.self
            )

            print("모임 생성 성공: \(response.postId)")

            await MainActor.run {
                state.isCreating = false
                state.isCreated = true
                state.createdPostId = response.postId
                state.showPaymentRequiredAlert = true
            }
        } catch {
            await MainActor.run {
                state.errorMessage = (error as? NetworkError)?.localizedDescription ?? "모임 생성에 실패했습니다."
                state.isCreating = false
                state.showErrorAlert = true
            }
        }
    }

    // MARK: - Update Meet

    private func updateMeet(postId: String) async {
        guard state.isFormValid else {
            await MainActor.run {
                state.errorMessage = "모든 필드를 입력해주세요."
                state.showErrorAlert = true
            }
            return
        }

        await MainActor.run {
            state.isUpdating = true
            state.errorMessage = nil
        }

        do {
            // 미디어 처리 (이미지 + 동영상)
            var files: [String] = []
            if !state.selectedMediaItems.isEmpty {
                files = try await uploadMedia(state.selectedMediaItems)
            } else if state.shouldKeepExistingMedia {
                files = state.existingMediaURLs
            }

            // additionalFields 구성
            let additionalFields = buildAdditionalFields()

            // API 호출
            let response = try await networkService.request(
                PostRouter.updatePost(
                    postId: postId,
                    title: state.title,
                    content: state.content,
                    files: files,
                    additionalFields: additionalFields
                ),
                responseType: PostDTO.self
            )

            print("모임 수정 성공: \(response.postId)")

            await MainActor.run {
                state.isUpdating = false
                state.isUpdated = true
            }
        } catch {
            await MainActor.run {
                state.errorMessage = (error as? NetworkError)?.localizedDescription ?? "모임 수정에 실패했습니다."
                state.isUpdating = false
                state.showErrorAlert = true
            }
        }
    }

    // MARK: - Helper Methods

    /// 미디어 업로드 (이미지 + 동영상)
    private func uploadMedia(_ mediaItems: [MediaItem]) async throws -> [String] {
        guard !mediaItems.isEmpty else {
            return []
        }

        // MediaItem에서 파일 정보 추출 (data, fileName, mimeType)
        let files = mediaItems.enumerated().map { index, item in
            let fileName = item.originalFileName ?? "\(item.type == .image ? "image" : "video")_\(index).\(item.fileExtension)"
            return (data: item.data, fileName: fileName, mimeType: item.mimeType)
        }

        // 서버에 업로드 (multipart/form-data)
        let fileDTO = try await networkService.multipartUpload(
            PostRouter.uploadFiles(images: files.map { $0.data }),
            files: files,
            responseType: FileDTO.self
        )

        return fileDTO.files
    }

    private func buildAdditionalFields() -> [String: String] {
        var fields: [String: String] = [:]

        // value1: 모집인원
        fields["value1"] = String(state.capacity)

        // value2: 성별제한
        fields["value2"] = String(state.gender.rawValue)

        // value3: 예약 정보 ISO 형식 (yyyyMMddHHmm,totalHours)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: state.meetingStartDate)
        let reservationISO = ReservationFormatter.createReservationISO(
            date: state.meetingStartDate,
            startHour: hour,
            totalHours: state.totalHours
        )
        // # 제거하고 전송
        fields["value3"] = reservationISO.trimmingCharacters(in: CharacterSet(charactersIn: "#"))

        // value4: 공간 정보 (spaceId|spaceName|address|imageURL)
        if let space = state.selectedSpace {
            let imageURL = space.imageURLs.first ?? ""
            fields["value4"] = "\(space.id)|\(space.title)|\(space.address)|\(imageURL)"
        }

        // value5: 모집 시작일 (ISO8601 with fractional seconds)
        fields["value5"] = DateFormatterManager.iso8601.string(from: state.recruitmentStartDate)

        // value6: 모집 종료일 (ISO8601 with fractional seconds)
        fields["value6"] = DateFormatterManager.iso8601.string(from: state.recruitmentEndDate)

        return fields
    }

    // MARK: - Validate Payment

    /// 결제 영수증 검증
    private func validatePayment(impUid: String, postId: String) async {

        await MainActor.run {
            state.isValidatingPayment = true
        }

        do {
            let response = try await networkService.request(
                PaymentRouter.validatePayment(impUid: impUid, postId: postId),
                responseType: PaymentHistoryDTO.self
            )

            await MainActor.run {
                state.isValidatingPayment = false
                state.paymentSuccessMessage = "모임 생성이 완료되었습니다."
                state.shouldNavigateToPayment = false
            }

        } catch {
            
            let errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription

            await MainActor.run {
                state.isValidatingPayment = false
                state.errorMessage = "결제 검증에 실패했습니다.\n\(errorMessage)\n\n고객센터로 문의해주세요."
                state.shouldNavigateToPayment = false
                state.showErrorAlert = true
            }
        }
    }

    // MARK: - Load Reservation Info from Comments

    /// 선택한 공간의 예약 정보를 댓글에서 로드
    private func loadReservationInfo(for spaceId: String) async {
        do {
            let response = try await networkService.request(
                CommentRouter.fetchComments(postId: spaceId),
                responseType: CommentListDTO.self
            )

            // 예약 정보 댓글 필터링 (#으로 시작하는 ISO 포맷)
            let reservationComments = response.data.filter { $0.content.hasPrefix("#") }

            // 내가 작성한 예약 댓글 찾기 (userID 일치)
            guard let currentUserId = TokenManager.shared.userId else {
                return
            }

            if let myComment = reservationComments.first(where: { $0.creator.userId == currentUserId }),
               let parsed = ReservationFormatter.parseReservationISO(myComment.content) {
                await MainActor.run {
                    state.reservationDate = parsed.date
                    state.reservationStartHour = parsed.startHour
                    state.reservationTotalHours = parsed.totalHours

                    // meetingStartDate와 totalHours도 업데이트
                    state.meetingStartDate = parsed.date
                    state.totalHours = parsed.totalHours

                    // 종료 시간 계산
                    if let endDate = Calendar.current.date(byAdding: .hour, value: parsed.totalHours, to: parsed.date) {
                        state.meetingEndDate = endDate
                    }

                    // 가격 재계산
                    state.pricePerPerson = state.calculatedPrice
                }
            }
        } catch {
            //TODO: - 에러처리
            print("예약 정보 로드 실패: \(error)")
        }
    }

    // MARK: - Media Loading Methods

    /// PhotosPickerItem에서 미디어 로드
    private func loadMediaFromPhotos(_ items: [PhotosPickerItem]) async {
        var loadedMediaItems: [MediaItem] = []
        var foundVideoURL: URL? = nil

        for item in items {
            do {
                // 동영상인지 확인
                if let movie = try await item.loadTransferable(type: Movie.self) {
                    // 동영상 발견
                    foundVideoURL = movie.url
                    break // 첫 번째 동영상만 처리
                }
                // 이미지 처리
                else if let data = try await item.loadTransferable(type: Data.self),
                        let image = UIImage(data: data) {
                    if let mediaItem = MediaItem.fromImage(image, maxSizeInMB: 10) {
                        loadedMediaItems.append(mediaItem)
                    }
                }
            } catch {
                // 미디어 로드 실패는 조용히 처리
                continue
            }
        }

        await MainActor.run {
            // 이미지가 있으면 먼저 추가
            if !loadedMediaItems.isEmpty {
                state.selectedMediaItems = loadedMediaItems
                state.shouldKeepExistingMedia = false
            }

            // 동영상이 있으면 View에서 처리할 수 있도록 별도 처리 필요
            // (View의 pendingVideoURL과 showVideoOptionAlert는 View에서만 관리)
        }
    }

    /// 선택된 이미지 처리 (커스텀 피커에서 호출)
    private func handleSelectedImages(_ images: [UIImage]) async {
        var mediaItems: [MediaItem] = []

        for image in images {
            if let mediaItem = MediaItem.fromImage(image, maxSizeInMB: 10) {
                mediaItems.append(mediaItem)
            }
        }

        await MainActor.run {
            var currentItems = state.selectedMediaItems
            currentItems.append(contentsOf: mediaItems)
            state.selectedMediaItems = currentItems
            state.shouldKeepExistingMedia = false
        }
    }

    /// 동영상 자동 압축
    private func autoCompressVideo(_ url: URL) async {
        if let mediaItem = await MediaItem.fromVideo(url, maxSizeInMB: 10) {
            await MainActor.run {
                var currentItems = state.selectedMediaItems
                currentItems.append(mediaItem)
                state.selectedMediaItems = currentItems
                state.shouldKeepExistingMedia = false

                // 임시 파일 삭제
                try? FileManager.default.removeItem(at: url)
            }
        } else {
            await MainActor.run {
                state.videoCompressionFailed = true
                // 실패해도 임시 파일 삭제
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}
