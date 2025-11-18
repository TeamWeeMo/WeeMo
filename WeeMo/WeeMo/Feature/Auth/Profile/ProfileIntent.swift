//
//  ProfileIntent.swift
//  WeeMo
//
//  Created by Lee on 11/17/25.
//

import Foundation

enum ProfileIntent {
    case tabChanged(ProfileTab)
    case loadInitialData
    case loadMyProfile
    case loadUserProfile(userId: String)  // 다른 사람 프로필 조회
    case loadUserMeetings
    case loadUserFeeds
    case loadLikedPosts
    case loadPaidPosts
    case refreshCurrentTab
}
