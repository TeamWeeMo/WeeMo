//
//  ChatRealmService.swift
//  WeeMo
//
//  Created by 차지용 on 11/20/25.
//

import Foundation
import RealmSwift

// MARK: - Chat Realm Service

/// 채팅 관련 Realm 서비스
class ChatRealmService {
    static let shared = ChatRealmService()
    private let realmManager = RealmManager.shared

    private init() {}

    // MARK: - Chat Room Operations

    /// 채팅방 저장
    func saveChatRoom(_ chatRoom: ChatRoomDTO) throws {
        let realmRoom = ChatRoomRealm(from: chatRoom)
        try realmManager.save(realmRoom)
    }

    /// 채팅방 목록 저장
    func saveChatRooms(_ chatRooms: [ChatRoomDTO]) throws {
        let realmRooms = chatRooms.map { ChatRoomRealm(from: $0) }
        try realmManager.save(realmRooms)
    }

    /// 모든 채팅방 조회
    func fetchChatRooms() -> [ChatRoom] {
        let realmRooms = realmManager.fetch(ChatRoomRealm.self)
        return realmRooms.compactMap { $0.toChatRoom() }
    }

    /// 특정 채팅방 조회
    func fetchChatRoom(roomId: String) -> ChatRoom? {
        guard let realmRoom = realmManager.fetch(ChatRoomRealm.self, primaryKey: roomId) else {
            return nil
        }
        return realmRoom.toChatRoom()
    }

    /// 채팅방 삭제
    func deleteChatRoom(roomId: String) throws {
        guard let chatRoom = realmManager.fetch(ChatRoomRealm.self, primaryKey: roomId) else { return }

        // 해당 채팅방의 모든 메시지도 삭제
        let messages = realmManager.fetch(ChatMessageRealm.self).where { $0.roomId == roomId }
        try realmManager.delete(messages)

        // 채팅방 삭제
        try realmManager.delete(chatRoom)
    }

    // MARK: - Chat Message Operations

    /// 채팅 메시지 저장
    func saveChatMessage(_ message: ChatMessageDTO) throws {
        let realmMessage = ChatMessageRealm(from: message)
        try realmManager.save(realmMessage)
    }

    /// 채팅 메시지 목록 저장
    func saveChatMessages(_ messages: [ChatMessageDTO]) throws {
        let realmMessages = messages.map { ChatMessageRealm(from: $0) }
        try realmManager.save(realmMessages)
    }

    /// 임시 메시지 저장 (전송 중)
    func saveTempMessage(content: String, roomId: String, sender: User) throws -> String {
        let tempMessage = ChatMessageRealm(tempMessage: content, roomId: roomId, sender: sender)
        try realmManager.save(tempMessage)
        return tempMessage.chatId
    }

    /// 임시 메시지를 실제 메시지로 업데이트
    func updateTempMessage(tempId: String, with message: ChatMessageDTO) throws {
        guard let tempMessage = realmManager.fetch(ChatMessageRealm.self, primaryKey: tempId) else { return }

        try realmManager.write {
            tempMessage.chatId = message.chatId
            tempMessage.createdAt = ISO8601DateFormatter().date(from: message.createdAt) ?? Date()
            tempMessage.isTemporary = false
            tempMessage.isSent = true
        }
    }

    /// 특정 채팅방의 메시지 조회
    func fetchChatMessages(roomId: String, limit: Int? = nil) -> [ChatMessage] {
        let realmMessages = realmManager.fetch(ChatMessageRealm.self)
            .where { $0.roomId == roomId }
            .sorted(byKeyPath: "createdAt", ascending: true)

        let messages = Array(realmMessages)
        let limitedMessages = limit != nil ? Array(messages.suffix(limit!)) : messages

        return limitedMessages.map { $0.toChatMessage() }
    }

    /// 최근 메시지 조회 (페이징)
    func fetchRecentMessages(roomId: String, before messageId: String? = nil, limit: Int = 50) -> [ChatMessage] {
        var query = realmManager.fetch(ChatMessageRealm.self).where { $0.roomId == roomId }

        if let messageId = messageId,
           let beforeMessage = realmManager.fetch(ChatMessageRealm.self, primaryKey: messageId) {
            query = query.where { $0.createdAt < beforeMessage.createdAt }
        }

        let realmMessages = query.sorted(byKeyPath: "createdAt", ascending: false)
        let limitedMessages = Array(realmMessages.prefix(limit))

        return limitedMessages.reversed().map { $0.toChatMessage() }
    }

    /// 임시 메시지 삭제 (전송 실패시)
    func deleteTempMessage(tempId: String) throws {
        guard let tempMessage = realmManager.fetch(ChatMessageRealm.self, primaryKey: tempId) else { return }
        try realmManager.delete(tempMessage)
    }

    /// 읽지 않은 메시지 수 조회 (임시 구현)
    func getUnreadCount(roomId: String, lastReadMessageId: String?) -> Int {
        var query = realmManager.fetch(ChatMessageRealm.self).where { $0.roomId == roomId }

        if let lastReadMessageId = lastReadMessageId,
           let lastReadMessage = realmManager.fetch(ChatMessageRealm.self, primaryKey: lastReadMessageId) {
            query = query.where { $0.createdAt > lastReadMessage.createdAt }
        }

        return query.count
    }

    /// 마지막 읽은 메시지 ID 업데이트
    func updateLastReadMessageId(roomId: String, messageId: String) throws {
        guard let chatRoom = realmManager.fetch(ChatRoomRealm.self, primaryKey: roomId) else { return }

        try realmManager.write {
            chatRoom.lastReadMessageId = messageId
        }
        print("마지막 읽은 메시지 업데이트: \(roomId) -> \(messageId)")
    }

    /// 마지막 읽은 메시지 ID 가져오기
    func getLastReadMessageId(roomId: String) -> String? {
        return realmManager.fetch(ChatRoomRealm.self, primaryKey: roomId)?.lastReadMessageId
    }

    // MARK: - User Operations

    /// 유저 저장
    func saveUser(_ user: UserDTO) throws {
        let realmUser = UserRealm(from: user)
        try realmManager.save(realmUser)
    }

    /// 유저 조회
    func fetchUser(userId: String) -> User? {
        guard let realmUser = realmManager.fetch(UserRealm.self, primaryKey: userId) else {
            return nil
        }
        return realmUser.toUser()
    }

    // MARK: - Utility

    /// 오래된 메시지 삭제 (성능 최적화)
    func deleteOldMessages(olderThan days: Int = 30) throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let oldMessages = realmManager.fetch(ChatMessageRealm.self).where { $0.createdAt < cutoffDate }
        try realmManager.delete(oldMessages)
    }

    /// 특정 날짜 이후의 메시지 삭제 (30일 정책용)
    func deleteMessagesAfter(date: Date, roomId: String) throws {
        let recentMessages = realmManager.fetch(ChatMessageRealm.self).where {
            $0.roomId == roomId && $0.createdAt > date
        }
        try realmManager.delete(recentMessages)
    }

    /// 채팅 데이터 전체 삭제
    func clearAllChatData() throws {
        let chatRooms = realmManager.fetch(ChatRoomRealm.self)
        let chatMessages = realmManager.fetch(ChatMessageRealm.self)

        try realmManager.delete(chatRooms)
        try realmManager.delete(chatMessages)
    }
}
