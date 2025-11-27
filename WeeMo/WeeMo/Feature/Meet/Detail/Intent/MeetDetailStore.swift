//
//  MeetDetailStore.swift
//  WeeMo
//
//  Created by 차지용 on 11/16/25.
//

import Foundation

// MARK: - Meet Detail Store

@Observable
final class MeetDetailStore {
    // MARK: - Properties

    private(set) var state = MeetDetailState()
    private let networkService: NetworkServiceProtocol
    private var currentPostId: String?

    // MARK: - Initializer

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Intent Handler

    func send(_ intent: MeetDetailIntent) {
        switch intent {
        case .onAppear(let postId):
            currentPostId = postId
            Task { await loadMeetDetail(postId: postId) }

        case .retryLoad:
            guard let postId = currentPostId else { return }
            Task { await loadMeetDetail(postId: postId) }

        case .joinMeet:
            guard let postId = currentPostId else { return }
            Task { await joinMeet(postId: postId) }

        case .createChatRoom(let opponentUserId):
            Task { await createChatRoom(with: opponentUserId) }

        case .navigateToEdit:
            state.shouldNavigateToEdit = true

        case .dismissError:
            state.errorMessage = nil

        case .dismissChatError:
            state.chatErrorMessage = nil

        case .clearChatNavigation:
            state.shouldNavigateToChat = false
            state.createdChatRoom = nil

        case .navigateToSpace(let spaceId):
            Task { await loadSpace(spaceId: spaceId) }

        case .clearSpaceNavigation:
            state.shouldNavigateToSpace = false
            state.loadedSpace = nil

        case .showPaymentConfirmAlert:
            state.showPaymentConfirmAlert = true

        case .dismissPaymentConfirmAlert:
            state.showPaymentConfirmAlert = false

        case .confirmPayment:
            state.showPaymentConfirmAlert = false
            state.shouldNavigateToPayment = true

        case .clearPaymentNavigation:
            state.shouldNavigateToPayment = false

        case .validatePayment(let impUid, let postId):
            Task { await validatePayment(impUid: impUid, postId: postId) }

        case .dismissPaymentSuccess:
            state.paymentSuccessMessage = nil

        case .dismissPaymentError:
            state.paymentErrorMessage = nil
        }
    }

    // MARK: - Private Methods

    private func loadMeetDetail(postId: String) async {
        await MainActor.run {
            state.isLoading = true
            state.errorMessage = nil
        }

        do {
            let postData = try await networkService.request(
                PostRouter.fetchPost(postId: postId),
                responseType: PostDTO.self
            )

            let meet = postData.toMeet()

            // 현재 사용자가 이미 참가했는지 확인
            let hasJoined = postData.buyers.contains(TokenManager.shared.userId ?? "")

            await MainActor.run {
                state.meet = meet
                state.hasJoined = hasJoined
                state.isLoading = false
            }

        } catch {
            await MainActor.run {
                state.errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                state.isLoading = false
            }
        }
    }

    private func joinMeet(postId: String) async {
        await MainActor.run {
            state.isJoining = true
            state.joinErrorMessage = nil
        }

        do {
            _ = try await networkService.request(
                PostRouter.buyPost(postId: postId),
                responseType: PaymentValidationDTO.self
            )

            await MainActor.run {
                state.isJoining = false
                state.hasJoined = true
            }

            // 참가 후 상세 정보 다시 로드
            await loadMeetDetail(postId: postId)

        } catch {
            await MainActor.run {
                state.joinErrorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription
                state.isJoining = false
            }
        }
    }

    private func createChatRoom(with opponentUserId: String) async {
        await MainActor.run {
            state.isCreatingChat = true
            state.chatErrorMessage = nil
        }

        do {
            let response = try await networkService.request(
                ChatRouter.createOrFetchRoom(opponentUserId: opponentUserId),
                responseType: ChatRoomDTO.self
            )

            let chatRoom = response.toDomain()

            await MainActor.run {
                state.createdChatRoom = chatRoom
                state.shouldNavigateToChat = true
                state.isCreatingChat = false
            }

        } catch {
            await MainActor.run {
                state.chatErrorMessage = "채팅방 생성에 실패했습니다: \(error.localizedDescription)"
                state.isCreatingChat = false
            }
        }
    }

    // MARK: - Load Space

    private func loadSpace(spaceId: String) async {
        await MainActor.run {
            state.isLoadingSpace = true
        }

        do {
            let postDTO = try await networkService.request(
                PostRouter.fetchPost(postId: spaceId),
                responseType: PostDTO.self
            )

            let space = postDTO.toSpace()

            await MainActor.run {
                state.loadedSpace = space
                state.shouldNavigateToSpace = true
                state.isLoadingSpace = false
            }

        } catch {
            await MainActor.run {
                state.isLoadingSpace = false
                print("[MeetDetailStore] 공간 조회 실패: \(error)")
            }
        }
    }

    // MARK: - Validate Payment

    private func validatePayment(impUid: String, postId: String) async {

        await MainActor.run {
            state.isValidatingPayment = true
            state.paymentErrorMessage = nil
        }

        do {
            let response = try await networkService.request(
                PaymentRouter.validatePayment(impUid: impUid, postId: postId),
                responseType: PaymentHistoryDTO.self
            )

            // 결제 완료 후 상세 정보 다시 로드
            await loadMeetDetail(postId: postId)

            await MainActor.run {
                state.isValidatingPayment = false
                state.paymentSuccessMessage = "모임 참가가 완료되었습니다."
                state.shouldNavigateToPayment = false
            }

        } catch {

            let errorMessage = (error as? NetworkError)?.localizedDescription ?? error.localizedDescription

            await MainActor.run {
                state.isValidatingPayment = false
                state.paymentErrorMessage = "결제 검증에 실패했습니다.\n\(errorMessage)\n\n고객센터로 문의해주세요."
                state.shouldNavigateToPayment = false
            }
        }
    }
}
