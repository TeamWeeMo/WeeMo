//
//  MeetEditStore.swift
//  WeeMo
//
//  Created by 차지용 on 11/14/25.
//

import Foundation
import Combine
import UIKit

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

        // MARK: - Image
        case .selectImages(let images):
            state.selectedImages = images
            if !images.isEmpty {
                state.shouldKeepExistingImages = false
            }

        case .removeImage(let index):
            if index < state.selectedImages.count {
                state.selectedImages.remove(at: index)
            }

        case .removeExistingImage(let index):
            if index < state.existingImageURLs.count {
                state.existingImageURLs.remove(at: index)
                if state.existingImageURLs.isEmpty {
                    state.shouldKeepExistingImages = false
                }
            }

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
        state.existingImageURLs = meet.imageURLs
        state.shouldKeepExistingImages = true
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
            // 이미지 업로드
            var files: [String] = []
            if !state.selectedImages.isEmpty {
                files = try await uploadImages(state.selectedImages)
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
            // 이미지 처리
            var files: [String] = []
            if !state.selectedImages.isEmpty {
                files = try await uploadImages(state.selectedImages)
            } else if state.shouldKeepExistingImages {
                files = state.existingImageURLs
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

    private func uploadImages(_ images: [UIImage]) async throws -> [String] {
        let imageDatas = ImageCompressor.compress(images, maxSizeInMB: 10, maxDimension: 2048)

        guard !imageDatas.isEmpty else {
            return []
        }

        let fileDTO = try await networkService.upload(
            PostRouter.uploadFiles(images: imageDatas),
            images: imageDatas,
            responseType: FileDTO.self
        )

        return fileDTO.files
    }

    private func buildAdditionalFields() -> [String: String] {
        var fields: [String: String] = [:]
        let formatter = ISO8601DateFormatter()

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

        // value5: 모집 시작일
        fields["value5"] = formatter.string(from: state.recruitmentStartDate)

        // value6: 모집 종료일
        fields["value6"] = formatter.string(from: state.recruitmentEndDate)

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
}
