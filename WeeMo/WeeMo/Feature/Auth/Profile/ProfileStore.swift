//
//  ProfileStore.swift
//  WeeMo
//
//  Created by Lee on 11/17/25.
//

import Foundation
import Combine

@MainActor
final class ProfileStore: ObservableObject {

    @Published private(set) var state = ProfileState()

    private let postService: PostServicing
    private let paymentService: PaymentServicing
    private let targetUserId: String?  // nil이면 내 프로필, 값이 있으면 해당 유저 프로필

    init(
        userId: String? = nil,
        postService: PostServicing = PostService(),
        paymentService: PaymentServicing = PaymentService()
    ) {
        self.targetUserId = userId
        self.postService = postService
        self.paymentService = paymentService
    }

    // 내 프로필인지 확인
    private var isMyProfile: Bool {
        guard let targetUserId = targetUserId else { return true }
        return targetUserId == TokenManager.shared.userId
    }

    func send(_ intent: ProfileIntent) {
        switch intent {
        case .tabChanged(let tab):
            state.selectedTab = tab

        case .loadInitialData:
            loadInitialData()

        case .loadMyProfile:
            loadMyProfile()

        case .loadUserProfile(let userId):
            loadUserProfile(userId: userId)

        case .loadUserMeetings:
            loadUserMeetings()

        case .loadUserFeeds:
            loadUserFeeds()

        case .loadReservedSpaces:
            loadReservedSpaces()

        case .loadLikedPosts:
            loadLikedPosts()

        case .loadPaidPosts:
            loadPaidPosts()

        case .refreshCurrentTab:
            refreshCurrentTab()
        }
    }

    private func loadInitialData() {
        print("[ProfileStore] loadInitialData 호출됨")
        print("[ProfileStore] targetUserId: \(targetUserId ?? "nil (내 프로필)")")

        // 병렬로 모든 데이터 로드
        if isMyProfile {
            loadMyProfile()
        } else if let userId = targetUserId {
            loadUserProfile(userId: userId)
        }

        // 작성한 모임, 피드는 병렬로 로드
        loadUserMeetings()
        loadUserFeeds()
    }

    private func loadMyProfile() {
        print("[ProfileStore] loadMyProfile 호출됨")
        guard !state.isLoadingProfile else {
            print("[ProfileStore] 이미 프로필 로딩 중")
            return
        }

        state.isLoadingProfile = true
        state.errorMessage = nil

        Task {
            do {
                let profileDTO = try await NetworkService().request(
                    UserRouter.fetchMyProfile,
                    responseType: ProfileDTO.self
                )
                let profile = profileDTO.toDomain()

                state.follower = profile.followers.count
                state.following = profile.following.count
                state.isLoadingProfile = false
                print("[ProfileStore] 프로필 로드 성공 - 팔로워: \(state.follower), 팔로잉: \(state.following)")
            } catch let error as NetworkError {
                print("[ProfileStore] 프로필 로드 에러: \(error)")
                state.isLoadingProfile = false
                state.errorMessage = error.localizedDescription
            } catch {
                print("[ProfileStore] 프로필 로드 에러: \(error)")
                state.isLoadingProfile = false
                state.errorMessage = "프로필을 불러오는데 실패했습니다"
            }
        }
    }

    private func loadUserProfile(userId: String) {
        print("[ProfileStore] loadUserProfile 호출됨 - userId: \(userId)")
        guard !state.isLoadingOtherProfile else {
            print("[ProfileStore] 이미 다른 사람 프로필 로딩 중")
            return
        }

        state.isLoadingOtherProfile = true
        state.errorMessage = nil

        Task {
            do {
                let profileDTO = try await NetworkService().request(
                    UserRouter.fetchUserProfile(userId: userId),
                    responseType: ProfileDTO.self
                )
                let profile = profileDTO.toDomain()

                state.otherUserProfile = profile
                state.isLoadingOtherProfile = false
                print("[ProfileStore] 다른 사람 프로필 로드 성공 - 닉네임: \(profile.nick), 팔로워: \(profile.followers.count), 팔로잉: \(profile.following.count)")
            } catch let error as NetworkError {
                print("[ProfileStore] 다른 사람 프로필 로드 에러: \(error)")
                state.isLoadingOtherProfile = false
                state.errorMessage = error.localizedDescription
            } catch {
                print("[ProfileStore] 다른 사람 프로필 로드 에러: \(error)")
                state.isLoadingOtherProfile = false
                state.errorMessage = "프로필을 불러오는데 실패했습니다"
            }
        }
    }

    private func loadUserMeetings() {
        print("[ProfileStore] loadUserMeetings 호출됨")

        // targetUserId가 있으면 그 값 사용, 없으면 내 userId 사용
        let userId = targetUserId ?? TokenManager.shared.userId
        guard let userId = userId else {
            print("[ProfileStore] userId가 없습니다!")
            state.errorMessage = "사용자 정보를 찾을 수 없습니다"
            return
        }
        print("[ProfileStore] userId: \(userId)")

        guard !state.isLoadingMeetings else {
            print("[ProfileStore] 이미 로딩 중")
            return
        }

        state.isLoadingMeetings = true
        state.errorMessage = nil

        Task {
            do {
                let result = try await postService.fetchUserPosts(
                    userId: userId,
                    next: nil,
                    limit: 20,
                    category: .meet
                )

                state.userMeetings = result.data
                state.meetingsNextCursor = result.nextCursor
                state.isLoadingMeetings = false
            } catch let error as NetworkError {
                print("작성한 모임 로드 에러: \(error)")
                state.isLoadingMeetings = false
                state.errorMessage = error.localizedDescription
            } catch {
                print("작성한 모임 로드 에러: \(error)")
                state.isLoadingMeetings = false
                state.errorMessage = "작성한 모임을 불러오는데 실패했습니다"
            }
        }
    }

    private func loadUserFeeds() {
        print("[ProfileStore] loadUserFeeds 호출됨")

        // targetUserId가 있으면 그 값 사용, 없으면 내 userId 사용
        let userId = targetUserId ?? TokenManager.shared.userId
        guard let userId = userId else {
            print("[ProfileStore] userId가 없습니다!")
            state.errorMessage = "사용자 정보를 찾을 수 없습니다"
            return
        }
        print("[ProfileStore] userId: \(userId)")

        guard !state.isLoadingFeeds else {
            print("[ProfileStore] 이미 로딩 중")
            return
        }

        state.isLoadingFeeds = true
        state.errorMessage = nil

        Task {
            do {
                let result = try await postService.fetchUserPosts(
                    userId: userId,
                    next: nil,
                    limit: 20,
                    category: .feed
                )

                print("[ProfileStore] 작성한 피드 로드 성공 - 데이터 개수: \(result.data.count)")
                print("[ProfileStore] 피드 제목들: \(result.data.map { $0.title })")
                state.userFeeds = result.data
                state.feedsNextCursor = result.nextCursor
                state.isLoadingFeeds = false
                print("[ProfileStore] state.userFeeds.count: \(state.userFeeds.count)")
            } catch let error as NetworkError {
                print("작성한 피드 로드 에러: \(error)")
                state.isLoadingFeeds = false
                state.errorMessage = error.localizedDescription
            } catch {
                print("작성한 피드 로드 에러: \(error)")
                state.isLoadingFeeds = false
                state.errorMessage = "작성한 피드를 불러오는데 실패했습니다"
            }
        }
    }

    private func loadLikedPosts() {
        guard !state.isLoadingLikedPosts else { return }

        state.isLoadingLikedPosts = true
        state.errorMessage = nil

        Task {
            do {
                let result = try await postService.fetchMyLikedPosts(
                    next: nil,
                    limit: 20,
                    category: .meet
                )

                state.likedPosts = result.data
                state.likedPostsNextCursor = result.nextCursor
                state.isLoadingLikedPosts = false
            } catch let error as NetworkError {
                print("찜한 모임 로드 에러: \(error)")
                state.isLoadingLikedPosts = false
                state.errorMessage = error.localizedDescription
            } catch {
                print("찜한 모임 로드 에러: \(error)")
                state.isLoadingLikedPosts = false
                state.errorMessage = "찜한 모임을 불러오는데 실패했습니다"
            }
        }
    }

    private func loadReservedSpaces() {
        guard !state.isLoadingReservedSpaces else { return }

        state.isLoadingReservedSpaces = true
        state.errorMessage = nil

        Task {
            do {
                let result = try await postService.fetchMyLikedPosts(
                    next: nil,
                    limit: 20,
                    category: .space
                )

                state.reservedSpaces = result.data
                state.reservedSpacesNextCursor = result.nextCursor
                state.isLoadingReservedSpaces = false
            } catch let error as NetworkError {
                print("예약한 공간 로드 에러: \(error)")
                state.isLoadingReservedSpaces = false
                state.errorMessage = error.localizedDescription
            } catch {
                print("예약한 공간 로드 에러: \(error)")
                state.isLoadingReservedSpaces = false
                state.errorMessage = "예약한 공간을 불러오는데 실패했습니다"
            }
        }
    }

    private func loadPaidPosts() {
        guard !state.isLoadingPaidPosts else { return }

        state.isLoadingPaidPosts = true
        state.errorMessage = nil

        Task {
            do {
                let result = try await paymentService.fetchMyPayments()

                state.paidPosts = result.data
                state.isLoadingPaidPosts = false
            } catch let error as NetworkError {
                print("결제한 모임 로드 에러: \(error)")
                state.isLoadingPaidPosts = false
                state.errorMessage = error.localizedDescription
            } catch {
                print("결제한 모임 로드 에러: \(error)")
                state.isLoadingPaidPosts = false
                state.errorMessage = "결제한 모임을 불러오는데 실패했습니다"
            }
        }
    }

    private func refreshCurrentTab() {
        switch state.selectedTab {
        case .posts:
            // 작성한 모임과 피드 새로고침
            state.userMeetings = []
            state.userFeeds = []
            state.meetingsNextCursor = nil
            state.feedsNextCursor = nil
            loadUserMeetings()
            loadUserFeeds()

        case .reservedSpaces:
            // 예약한 공간 새로고침
            state.reservedSpaces = []
            state.reservedSpacesNextCursor = nil
            loadReservedSpaces()

        case .likeMeets:
            // 찜한 모임 새로고침
            state.likedPosts = []
            state.likedPostsNextCursor = nil
            loadLikedPosts()

        case .likes:
            // 결제한 모임 새로고침
            state.paidPosts = []
            loadPaidPosts()
        }
    }
}
