//
//  ChatRoomRealm.swift
//  WeeMo
//
//  Created by 차지용 on 11/20/25.
//

import Foundation
import RealmSwift

// MARK: - Realm Chat Room Model

/// Realm용 채팅방 모델
class ChatRoomRealm: Object {
    @Persisted var roomId: String = ""
    @Persisted var createdAt: Date = Date()
    @Persisted var updatedAt: Date = Date()
    @Persisted var participants: List<UserRealm> = List<UserRealm>()
    @Persisted var lastChatId: String? = nil
    @Persisted var lastChatContent: String = ""
    @Persisted var lastChatCreatedAt: Date? = nil
    @Persisted var lastChatSenderId: String = ""

    override static func primaryKey() -> String? {
        return "roomId"
    }

    /// Chat 모델로 변환
    func toChatRoom() -> ChatRoom? {
        let users = Array(participants.compactMap { $0.toUser() })

        var lastChat: ChatMessage? = nil
        if let lastChatId = lastChatId,
           let lastChatCreatedAt = lastChatCreatedAt,
           let sender = users.first(where: { $0.userId == lastChatSenderId }) {
            lastChat = ChatMessage(
                id: lastChatId,
                roomId: roomId,
                content: lastChatContent,
                createdAt: lastChatCreatedAt,
                sender: sender,
                files: []
            )
        }

        return ChatRoom(
            id: roomId,
            participants: users,
            lastChat: lastChat,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// ChatRoomDTO로부터 생성
    convenience init(from dto: ChatRoomDTO) {
        self.init()
        self.roomId = dto.roomId
        self.createdAt = ISO8601DateFormatter().date(from: dto.createdAt) ?? Date()
        self.updatedAt = ISO8601DateFormatter().date(from: dto.updatedAt) ?? Date()

        // 참여자 설정
        self.participants.removeAll()
        for userDTO in dto.participants {
            let userRealm = UserRealm(from: userDTO)
            self.participants.append(userRealm)
        }

        // 마지막 채팅 설정
        if let lastChatDTO = dto.lastChat {
            self.lastChatId = lastChatDTO.chatId
            self.lastChatContent = lastChatDTO.content
            self.lastChatCreatedAt = ISO8601DateFormatter().date(from: lastChatDTO.createdAt) ?? Date()
            self.lastChatSenderId = lastChatDTO.sender.userId
        }
    }
}
