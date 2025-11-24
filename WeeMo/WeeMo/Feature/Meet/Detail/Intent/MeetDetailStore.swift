//
//  MeetDetailViewModel.swift
//  WeeMo
//
//  Created by 차지용 on 11/16/25.
//

import Foundation
import Combine

final class MeetDetailStore: ObservableObject {
    @Published var state = MeetDetailState()
    private let networkService = NetworkService()

    func handle(_ intent: MeetDetailIntent) {
        switch intent {
        case .loadMeetDetail(let postId):
            loadMeetDetail(postId: postId)
        case .retryLoadMeetDetail:
            if let currentPostId = state.meetDetail?.postId {
                loadMeetDetail(postId: currentPostId)
            }
        case .joinMeet(let postId):
            joinMeet(postId: postId)
        }
    }

    private func loadMeetDetail(postId: String) {
        state.isLoading = true
        state.errorMessage = nil

        Task {
            do {
                print("🔄 Loading meet detail for postId: \(postId)")

                // PostRouter.fetchPost를 사용해 단일 포스트 조회
                let postData = try await networkService.request(
                    PostRouter.fetchPost(postId: postId),
                    responseType: PostDTO.self
                )

                print("✅ Meet detail loaded: \(postData.title)")

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
                    state.meetDetail = meetDetail
                    state.isLoading = false
                }

            } catch {
                print("❌ Error loading meet detail: \(error)")
                await MainActor.run {
                    state.errorMessage = error.localizedDescription
                    state.isLoading = false
                }
            }
        }
    }

    private func joinMeet(postId: String) {
        state.isJoining = true
        state.joinErrorMessage = nil

        Task {
            do {
                print("🔄 Joining meet: \(postId)")

                // 모임 참가 API 호출 (결제 검증 API 사용)
                let response = try await networkService.request(
                    PostRouter.buyPost(postId: postId),
                    responseType: PaymentValidationDTO.self
                )

                print("✅ Successfully joined meet")

                await MainActor.run {
                    state.isJoining = false
                    state.hasJoined = true
                    // 참가 후 다시 상세 정보 로드
                    loadMeetDetail(postId: postId)
                }

            } catch {
                print("❌ Error joining meet: \(error)")
                await MainActor.run {
                    state.joinErrorMessage = error.localizedDescription
                    state.isJoining = false
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

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "M월 d일 (E) HH:mm"
        displayFormatter.locale = Locale(identifier: "ko_KR")
        return displayFormatter.string(from: date)
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
}
