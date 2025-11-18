//
//  SpaceDetailStore.swift
//  WeeMo
//
//  Created by Reimos on 11/17/25.
//

import Combine
import SwiftUI

// MARK: - Space Detail Store

final class SpaceDetailStore: ObservableObject {
    @Published private(set) var state = SpaceDetailState()

    private let networkService: NetworkService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer

    init(networkService: NetworkService = NetworkService(), pricePerHour: Int) {
        self.networkService = networkService
        self.state.pricePerHour = pricePerHour
    }

    // MARK: - Bindings

    var startHourBinding: Binding<Int?> {
        Binding(
            get: { self.state.startHour },
            set: { self.state.startHour = $0 }
        )
    }

    var endHourBinding: Binding<Int?> {
        Binding(
            get: { self.state.endHour },
            set: { self.state.endHour = $0 }
        )
    }

    // MARK: - Intent Handler

    func send(_ intent: SpaceDetailIntent) {
        switch intent {
        case .viewAppeared:
            handleViewAppeared()

        case .dateSelected(let date):
            state.selectedDate = date

        case .profileLoaded:
            break

        case .reservationButtonTapped:
            handleReservation()
        }
    }

    // MARK: - Private Methods

    private func handleViewAppeared() {
        Task {
            await loadUserProfile()
        }
    }

    /// 사용자 프로필 로드
    private func loadUserProfile() async {
        await MainActor.run {
            state.isLoading = true
            state.errorMessage = nil
        }

        do {
            let profileDTO = try await networkService.request(
                UserRouter.fetchMyProfile,
                responseType: ProfileDTO.self
            )

            await MainActor.run {
                state.userNickname = profileDTO.nick

                // 이미지 URL 처리: 상대 경로면 전체 URL로 변환
                if !profileDTO.profileImage.isEmpty {
                    if profileDTO.profileImage.hasPrefix("http") {
                        state.userProfileImage = profileDTO.profileImage
                    } else {
                        // 상대 경로를 전체 URL로 변환
                        state.userProfileImage = NetworkConstants.baseURL + profileDTO.profileImage
                    }
                } else {
                    state.userProfileImage = nil
                }

                state.isLoading = false
            }

            print("[SpaceDetailStore] 사용자 프로필 로드 완료: \(profileDTO.nick)")
        } catch {
            await MainActor.run {
                state.isLoading = false
                state.errorMessage = "프로필을 불러올 수 없습니다."
                print("[SpaceDetailStore] 프로필 로드 에러: \(error)")
            }
        }
    }

    private func handleReservation() {
        guard state.canReserve else {
            print("[SpaceDetailStore] 예약 불가: 날짜 또는 시간 미선택")
            return
        }

        // 예약 정보 토글
        state.showReservationInfo.toggle()

        if state.showReservationInfo {
            print("[SpaceDetailStore] 예약 정보 표시:")
            print("- 날짜: \(state.formattedDate)")
            print("- 시간: \(state.formattedTimeSlot)")
            print("- 가격: \(state.totalPrice)")
        } else {
            print("[SpaceDetailStore] 예약 정보 숨김")
        }

        // TODO: 예약 API 호출 (showReservationInfo가 true일 때)
    }
}
