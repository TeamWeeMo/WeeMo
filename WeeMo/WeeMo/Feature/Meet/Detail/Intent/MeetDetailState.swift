//
//  MeetDetailState.swift
//  WeeMo
//
//  Created by 차지용 on 11/16/25.
//

import Foundation

struct MeetDetailState {
    var meetDetail: MeetDetail? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var isJoining: Bool = false
    var joinErrorMessage: String? = nil
    var hasJoined: Bool = false
}

struct MeetDetail: Equatable {
    let postId: String
    let title: String
    let content: String
    let creator: Creator
    let date: String
    let location: String
    let address: String
    let price: String
    let capacity: Int
    let currentParticipants: Int
    let participants: [Participant]
    let imageNames: [String]
    let daysLeft: String
    let gender: String
    let spaceInfo: SpaceInfo?

    struct Creator: Equatable {
        let userId: String
        let nickname: String
        let profileImage: String?
    }

    struct Participant: Equatable {
        let userId: String
        let nickname: String
        let profileImage: String?
    }

    struct SpaceInfo: Equatable {
        let spaceId: String
        let title: String
        let address: String
    }
}
