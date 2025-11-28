//
//  ProfileState.swift
//  WeeMo
//
//  Created by Lee on 11/17/25.
//

import Foundation

struct ProfileState {
    // 탭 선택
    var selectedTab: ProfileTab = .posts

    // 데이터
    var userMeetings: [PostDTO] = []          // 작성한 모임
    var userFeeds: [PostDTO] = []             // 작성한 피드
    var reservedSpaces: [PostDTO] = []        // 예약한 공간
    var likedPosts: [PostDTO] = []            // 찜한 모임
    var paidPosts: [PaymentHistoryDTO] = []   // 결제한 모임

    // 페이지네이션 커서
    var meetingsNextCursor: String? = nil
    var feedsNextCursor: String? = nil
    var reservedSpacesNextCursor: String? = nil
    var likedPostsNextCursor: String? = nil

    // 로딩 상태
    var isLoadingProfile: Bool = false
    var isLoadingMeetings: Bool = false
    var isLoadingFeeds: Bool = false
    var isLoadingReservedSpaces: Bool = false
    var isLoadingLikedPosts: Bool = false
    var isLoadingPaidPosts: Bool = false

    // 에러 메시지
    var errorMessage: String? = nil

    // 프로필 정보 (추후 확장 가능)
    var nickname: String = "닉네임"
    var following: Int = 0
    var follower: Int = 0

    // 다른 사람 프로필 조회 (피드 화면 등에서 사용)
    var otherUserProfile: Profile? = nil
    var isLoadingOtherProfile: Bool = false
}
