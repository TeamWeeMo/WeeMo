//
//  ChatMessageRealm.swift
//  WeeMo
//
//  Created by 차지용 on 11/20/25.
//

import Foundation
import RealmSwift

// MARK: - Realm Chat Message Model

/// Realm용 채팅 메시지 모델
class ChatMessageRealm: Object {
    @Persisted var chatId: String = ""
    @Persisted var roomId: String = ""
    @Persisted var content: String = ""
    @Persisted var createdAt: Date = Date()
    @Persisted var senderId: String = ""
    @Persisted var senderName: String = ""
    @Persisted var senderProfileImage: String = ""
    @Persisted var files: List<String> = List<String>()
    @Persisted var isTemporary: Bool = false // 임시 메시지 (전송 중)
    @Persisted var isSent: Bool = false // 전송 완료 여부

    override static func primaryKey() -> String? {
        return "chatId"
    }

    /// ChatMessage 모델로 변환
    func toChatMessage() -> ChatMessage {
        let sender = User(
            userId: senderId,
            nickname: senderName,
            profileImageURL: senderProfileImage
        )

        return ChatMessage(
            id: chatId,
            roomId: roomId,
            content: content,
            createdAt: createdAt,
            sender: sender,
            files: Array(files)
        )
    }

    /// ChatMessageDTO로부터 생성
    convenience init(from dto: ChatMessageDTO) {
        self.init()
        self.chatId = dto.chatId
        self.roomId = dto.roomId
        self.content = dto.content
        self.createdAt = ISO8601DateFormatter().date(from: dto.createdAt) ?? Date()
        self.senderId = dto.sender.userId
        self.senderName = dto.sender.nick
        self.senderProfileImage = dto.sender.profileImage ?? ""

        self.files.removeAll()
        for file in dto.files {
            self.files.append(file)
        }

        self.isTemporary = false
        self.isSent = true
    }

    /// 임시 메시지 생성 (전송 중)
    convenience init(tempMessage content: String, roomId: String, sender: User) {
        self.init()
        self.chatId = UUID().uuidString
        self.roomId = roomId
        self.content = content
        self.createdAt = Date()
        self.senderId = sender.userId
        self.senderName = sender.nickname
        self.senderProfileImage = sender.profileImageURL ?? ""
        self.isTemporary = true
        self.isSent = false
    }
}
