//
//  ChatMapper.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation

// MARK: - Chat Mapper

extension ChatMessageDTO {
    /// DTO → Domain Model 변환
    func toDomain() -> ChatMessage {
        // ISO8601 날짜 파싱
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = dateFormatter.date(from: createdAt) ?? Date()

        return ChatMessage(
            id: chatId,
            roomId: roomId,
            content: content,
            createdAt: date,
            sender: sender.toDomain(),
            files: files
        )
    }
}

extension ChatRoomDTO {
    /// DTO → Domain Model 변환
    func toDomain() -> ChatRoom {
        // ISO8601 날짜 파싱
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let createdDate = dateFormatter.date(from: createdAt) ?? Date()
        let updatedDate = dateFormatter.date(from: updatedAt) ?? Date()

        return ChatRoom(
            id: roomId,
            participants: participants.toDomain(),
            lastChat: lastChat?.toDomain(),
            createdAt: createdDate,
            updatedAt: updatedDate
        )
    }
}

extension Array where Element == ChatRoomDTO {
    /// DTO 배열 → Domain Model 배열 변환
    func toDomain() -> [ChatRoom] {
        return map { $0.toDomain() }
    }
}

extension Array where Element == ChatMessageDTO {
    /// DTO 배열 → Domain Model 배열 변환
    func toDomain() -> [ChatMessage] {
        return map { $0.toDomain() }
    }
}
