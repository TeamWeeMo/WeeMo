//
//  ChatDTO.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation

// MARK: - Chat DTOs

/// 채팅방 생성/조회 응답
struct ChatRoomResponseDTO: Decodable {
    let opponentId: String

    enum CodingKeys: String, CodingKey {
        case opponentId = "opponent_id"
    }
}

/// 채팅 메시지 DTO
struct ChatMessageDTO: Decodable {
    let chatId: String
    let roomId: String
    let content: String
    let createdAt: String
    let sender: UserDTO
    let files: [String]

    enum CodingKeys: String, CodingKey {
        case chatId = "chat_id"
        case roomId = "room_id"
        case content
        case createdAt
        case sender
        case files
    }
}

/// 채팅방 DTO
struct ChatRoomDTO: Decodable {
    let roomId: String
    let createdAt: String
    let updatedAt: String
    let participants: [UserDTO]
    let lastChat: ChatMessageDTO?

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case createdAt
        case updatedAt
        case participants
        case lastChat
    }
}

/// 채팅방 목록 응답
struct ChatRoomListDTO: Decodable {
    let data: [ChatRoomDTO]
}
