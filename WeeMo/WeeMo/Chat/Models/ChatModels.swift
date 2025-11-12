//
//  ChatModels.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/10/25.
//

import Foundation

// MARK: - User Model

struct User: Hashable, Identifiable {
    let id = UUID()
    let userId: String
    let nickname: String
    let profileImageURL: String?
}

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
        participants.first
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

// MARK: - Date Extension (시간 표시)

extension Date {
    /// 상대 시간 문자열 ("방금 전", "3분 전", "어제", "2024.05.06")
    func chatTimeAgoString() -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)

        if let minute = components.minute, minute < 1 {
            return "방금 전"
        } else if let minute = components.minute, minute < 60 {
            return "\(minute)분 전"
        } else if let hour = components.hour, hour < 24 {
            return "\(hour)시간 전"
        } else if let day = components.day, day == 1 {
            return "어제"
        } else if let day = components.day, day < 7 {
            return "\(day)일 전"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy.MM.dd"
            return formatter.string(from: self)
        }
    }

    /// 채팅 메시지용 시간 표시 ("오후 3:24")
    func chatTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self)
    }
}
