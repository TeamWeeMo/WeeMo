//
//  Chat.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/12/25.
//

import Foundation

// MARK: - Chat Room (채팅방)

/// 채팅방 정보
struct ChatRoom: Identifiable, Hashable {
    let id: String  // room_id
    let participants: [User]
    let lastChat: ChatMessage?
    let createdAt: Date
    let updatedAt: Date

    /// 상대방 정보 (1:1 채팅 기준)
    var otherUser: User? {
        // 현재 사용자 ID 가져오기
        guard let currentUserId = TokenManager.shared.userId else {
            return participants.first // 토큰 없으면 첫 번째 참여자 반환
        }

        // 현재 사용자가 아닌 참여자 찾기
        return participants.first { $0.userId != currentUserId }
    }

    /// 특정 사용자 기준으로 상대방 찾기
    func otherUser(currentUserId: String) -> User? {
        return participants.first { $0.userId != currentUserId }
    }

    /// 마지막 메시지 시간 표시용
    var lastChatTime: String {
        guard let lastChat = lastChat else { return "" }
        return lastChat.createdAt.chatTimeAgoString()
    }
}

// MARK: - Chat Message (채팅 메시지)

/// 채팅 메시지
struct ChatMessage: Identifiable, Hashable {
    let id: String  // chat_id
    let roomId: String
    let content: String
    let createdAt: Date
    let sender: User
    let files: [String]

    /// 이미지/비디오 파일 포함 여부
    var hasMedia: Bool {
        !files.isEmpty
    }

    /// 내가 보낸 메시지인지 확인 (임시)
    func isMine(currentUserId: String) -> Bool {
        sender.userId == currentUserId
    }
}
