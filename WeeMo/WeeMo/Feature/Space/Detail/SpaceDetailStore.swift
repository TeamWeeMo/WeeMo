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
    private let postService: PostService
    private let commentService: CommentService
    private let spaceId: String
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initializer

    init(
        networkService: NetworkService = NetworkService(),
        postService: PostService = PostService(),
        commentService: CommentService = CommentService(),
        spaceId: String,
        pricePerHour: Int
    ) {
        self.networkService = networkService
        self.postService = postService
        self.commentService = commentService
        self.spaceId = spaceId
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
            await loadReservationComments()
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

            // 좋아요(예약) API 호출
            Task {
                await likeSpace()
            }
        } else {
            print("[SpaceDetailStore] 예약 정보 숨김")
        }
    }

    /// 공간 좋아요(예약) API 호출
    private func likeSpace() async {
        // 예약 전 선택된 시간 저장
        guard let selectedDate = state.selectedDate,
              let startHour = state.startHour,
              let endHour = state.endHour else { return }

        // 총 예약 시간 계산
        let totalHours = endHour - startHour

        await MainActor.run {
            state.isLikeLoading = true
        }

        do {
            let response = try await postService.likePost(
                postId: spaceId,
                likeStatus: true
            )

            // 좋아요 성공 시 예약 정보를 댓글로 저장
            if response.likeStatus {
                await saveReservationComment(
                    date: selectedDate,
                    startHour: startHour,
                    totalHours: totalHours
                )
            }

            await MainActor.run {
                state.isLiked = response.likeStatus
                state.isLikeLoading = false

                // 예약 성공 시 해당 시간 블락 처리
                if response.likeStatus {
                    addBlockedHours(date: selectedDate, startHour: startHour, endHour: endHour)
                }
            }

            print("[SpaceDetailStore] 공간 예약(좋아요) 성공: \(response.likeStatus)")
        } catch {
            await MainActor.run {
                state.isLikeLoading = false
                state.errorMessage = "예약에 실패했습니다."
            }

            print("[SpaceDetailStore] 공간 예약(좋아요) 실패: \(error)")
        }
    }

    /// 예약 정보를 댓글로 저장 (ISO 형식: #yyyyMMddHHmm, 총시간)
    private func saveReservationComment(date: Date, startHour: Int, totalHours: Int) async {
        // DateFormatterManager 활용하여 날짜 포맷팅
        let dateString = DateFormatterManager.reservation.string(from: date)
        let startHourString = String(format: "%02d00", startHour)

        // 최종 포맷: #202511240100, 3
        let reservationContent = "#\(dateString)\(startHourString), \(totalHours)"

        do {
            let comment = try await commentService.createComment(
                postId: spaceId,
                content: reservationContent
            )

            print("[SpaceDetailStore] 예약 댓글 저장 성공: \(comment.commentId) - \(reservationContent)")
        } catch {
            print("[SpaceDetailStore] 예약 댓글 저장 실패: \(error)")
            // 댓글 저장 실패해도 예약 자체는 성공한 것으로 처리
        }
    }

    /// 예약된 시간을 블락 목록에 추가
    private func addBlockedHours(date: Date, startHour: Int, endHour: Int) {
        let calendar = Calendar.current
        let dateOnly = calendar.startOfDay(for: date)

        // 해당 날짜의 기존 블락된 시간 가져오기
        var blockedHours = state.blockedHoursByDate[dateOnly] ?? []

        // 선택된 시간 범위를 블락 목록에 추가
        for hour in startHour..<endHour {
            blockedHours.insert(hour)
        }

        state.blockedHoursByDate[dateOnly] = blockedHours

        // 선택 초기화
        state.startHour = nil
        state.endHour = nil

        print("[SpaceDetailStore] 블락된 시간 추가: \(dateOnly) - \(startHour):00 ~ \(endHour):00")
    }

    /// 서버에서 예약 댓글 조회 및 블락 시간 적용
    private func loadReservationComments() async {
        do {
            let comments = try await commentService.fetchComments(postId: spaceId)

            // 예약 정보 댓글 필터링 (#으로 시작하는 ISO 포맷)
            let reservationComments = comments.filter { $0.content.hasPrefix("#") }

            if reservationComments.isEmpty {
                print("[SpaceDetailStore] 📋 저장된 예약 정보가 없습니다.")
            } else {
                print("[SpaceDetailStore] 📋 저장된 예약 정보 (\(reservationComments.count)건):")
                print("========================================")

                for (index, comment) in reservationComments.enumerated() {
                    print("[\(index + 1)] 예약자: \(comment.creator.nick)")
                    print("    작성일: \(comment.createdAt)")
                    print("    원본: \(comment.content)")

                    // ISO 포맷 파싱: #202511240100, 3
                    if let reservationInfo = parseReservationISO(comment.content) {
                        let endHour = reservationInfo.startHour + reservationInfo.totalHours
                        let price = state.pricePerHour * reservationInfo.totalHours

                        print("    - 날짜: \(DateFormatterManager.reservation.string(from: reservationInfo.date))")
                        print("    - 시간: \(String(format: "%02d:00 - %02d:00", reservationInfo.startHour, endHour))")
                        print("    - 금액: \(price.formatted())원")

                        await MainActor.run {
                            addBlockedHoursFromServer(
                                date: reservationInfo.date,
                                startHour: reservationInfo.startHour,
                                endHour: endHour
                            )
                        }
                        print("    ✅ 타임라인에 블락 적용됨")
                    }
                    print("----------------------------------------")
                }
                print("========================================")
            }
        } catch {
            print("[SpaceDetailStore] 예약 댓글 조회 실패: \(error)")
        }
    }

    /// ISO 포맷 예약 댓글 파싱 (예: "#202511240100, 3" -> (date, startHour, totalHours))
    private func parseReservationISO(_ content: String) -> (date: Date, startHour: Int, totalHours: Int)? {
        // # 제거 후 콤마로 분리
        let trimmed = content.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("#") else { return nil }

        let withoutHash = String(trimmed.dropFirst())
        let components = withoutHash.components(separatedBy: ",")
        guard components.count == 2 else { return nil }

        let dateTimeString = components[0].trimmingCharacters(in: .whitespaces)
        let hoursString = components[1].trimmingCharacters(in: .whitespaces)

        // dateTimeString: "202511240100" (12자리)
        guard dateTimeString.count == 12 else { return nil }

        // 날짜 파싱: yyyyMMdd (앞 8자리)
        let dateString = String(dateTimeString.prefix(8))
        guard let date = DateFormatterManager.reservation.date(from: dateString) else { return nil }

        // 시간 파싱: HHmm (뒤 4자리 중 앞 2자리)
        let timeString = String(dateTimeString.suffix(4).prefix(2))
        guard let startHour = Int(timeString) else { return nil }

        // 총 시간 파싱
        guard let totalHours = Int(hoursString) else { return nil }

        return (date: date, startHour: startHour, totalHours: totalHours)
    }

    /// 서버에서 조회한 예약 시간을 블락 목록에 추가 (선택 초기화 없음)
    private func addBlockedHoursFromServer(date: Date, startHour: Int, endHour: Int) {
        let calendar = Calendar.current
        let dateOnly = calendar.startOfDay(for: date)

        // 해당 날짜의 기존 블락된 시간 가져오기
        var blockedHours = state.blockedHoursByDate[dateOnly] ?? []

        // 선택된 시간 범위를 블락 목록에 추가
        for hour in startHour..<endHour {
            blockedHours.insert(hour)
        }

        state.blockedHoursByDate[dateOnly] = blockedHours

        print("[SpaceDetailStore] 서버 예약 블락 추가: \(dateOnly) - \(startHour):00 ~ \(endHour):00")
    }
}
