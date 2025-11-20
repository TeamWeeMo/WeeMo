//
//  ChatService.swift
//  WeeMo
//
//  Created by 차지용 on 11/20/25.
//

import Foundation
import Combine

// MARK: - Chat Service

/// 채팅 관련 서비스 (HTTP 통신 + Realm 저장)
class ChatService {
    static let shared = ChatService()

    private let networkService = NetworkService()
    private let realmService = ChatRealmService.shared
    private let webSocketService = ChatWebSocketService.shared

    private init() {}

    // MARK: - Chat Room Operations

    /// 채팅방 생성 또는 조회
    func createOrFetchRoom(opponentUserId: String) async throws -> ChatRoomResponseDTO {
        let response = try await networkService.request(
            ChatRouter.createOrFetchRoom(opponentUserId: opponentUserId),
            responseType: ChatRoomResponseDTO.self
        )
        return response
    }

    /// 채팅방 목록 조회 (서버 + 로컬)
    func fetchChatRooms() async throws -> [ChatRoom] {
        do {
            // 서버에서 최신 데이터 가져오기
            let response = try await networkService.request(
                ChatRouter.fetchRoomList,
                responseType: ChatRoomListDTO.self
            )

            // Realm에 저장
            try realmService.saveChatRooms(response.data)

            // Realm에서 조회하여 반환
            return realmService.fetchChatRooms()

        } catch {
            // 네트워크 오류시 로컬 데이터 반환
            print("⚠️ Network error, returning cached data: \(error)")
            return realmService.fetchChatRooms()
        }
    }

    /// 특정 채팅방 조회 (로컬)
    func getChatRoom(roomId: String) -> ChatRoom? {
        return realmService.fetchChatRoom(roomId: roomId)
    }

    // MARK: - Chat Message Operations

    /// 채팅 메시지 목록 조회 (서버 + 로컬)
    func fetchMessages(roomId: String, cursorDate: String? = nil) async throws -> [ChatMessage] {
        do {
            // 서버에서 메시지 가져오기
            let response = try await networkService.request(
                ChatRouter.fetchMessages(roomId: roomId, cursorDate: cursorDate),
                responseType: [ChatMessageDTO].self
            )

            // Realm에 저장
            try realmService.saveChatMessages(response)

            // 로컬에서 조회하여 반환
            return realmService.fetchChatMessages(roomId: roomId)

        } catch {
            // 네트워크 오류시 로컬 데이터 반환
            print("⚠️ Network error, returning cached messages: \(error)")
            return realmService.fetchChatMessages(roomId: roomId)
        }
    }

    /// 메시지 전송
    func sendMessage(roomId: String, content: String, files: [String]? = nil) async throws -> ChatMessage {
        // 현재 유저 정보 (임시)
        guard let currentUser = getCurrentUser() else {
            throw ChatError.userNotFound
        }

        // 1. 임시 메시지 생성 및 로컬 저장
        let tempMessageId = try realmService.saveTempMessage(
            content: content,
            roomId: roomId,
            sender: currentUser
        )

        do {
            // 2. 서버로 메시지 전송
            let response = try await networkService.request(
                ChatRouter.sendMessage(roomId: roomId, content: content, files: files),
                responseType: ChatMessageDTO.self
            )

            // 3. 임시 메시지를 실제 메시지로 업데이트
            try realmService.updateTempMessage(tempId: tempMessageId, with: response)

            // 4. 웹소켓으로 실시간 전송 (선택적)
            webSocketService.sendMessage(roomId: roomId, content: content, files: files)

            return response.toChatMessage()

        } catch {
            // 5. 전송 실패시 임시 메시지 삭제
            try realmService.deleteTempMessage(tempId: tempMessageId)
            throw error
        }
    }

    /// 로컬 메시지 목록 조회 (실시간 업데이트용)
    func getLocalMessages(roomId: String, limit: Int? = nil) -> [ChatMessage] {
        return realmService.fetchChatMessages(roomId: roomId, limit: limit)
    }

    /// 더 이전 메시지 로드 (페이징)
    func loadMoreMessages(roomId: String, beforeMessageId: String, limit: Int = 50) async throws -> [ChatMessage] {
        // 로컬에서 해당 메시지의 날짜 찾기
        let localMessages = realmService.fetchChatMessages(roomId: roomId)
        guard let beforeMessage = localMessages.first(where: { $0.id == beforeMessageId }) else {
            return []
        }

        let cursorDate = ISO8601DateFormatter().string(from: beforeMessage.createdAt)

        // 서버에서 이전 메시지들 가져오기
        let response = try await networkService.request(
            ChatRouter.fetchMessages(roomId: roomId, cursorDate: cursorDate),
            responseType: [ChatMessageDTO].self
        )

        // Realm에 저장
        try realmService.saveChatMessages(response)

        // 페이징된 결과 반환
        return realmService.fetchRecentMessages(roomId: roomId, before: beforeMessageId, limit: limit)
    }

    // MARK: - File Upload

    /// 채팅 파일 업로드
    func uploadChatFiles(roomId: String, files: [Data]) async throws -> [String] {
        // 파일 업로드 로직 (구현 필요)
        // 임시로 빈 배열 반환
        return []
    }

    // MARK: - Helper Methods

    /// 현재 유저 정보 가져오기 (임시 구현)
    private func getCurrentUser() -> User? {
        // TokenManager 또는 UserDefaults에서 현재 유저 정보 가져오기
        // 임시 구현
        return User(
            userId: "current_user_id",
            nickname: "현재 사용자",
            profileImageURL: nil
        )
    }
}

// MARK: - Chat Error

enum ChatError: Error, LocalizedError {
    case userNotFound
    case roomNotFound
    case messageNotFound
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "사용자 정보를 찾을 수 없습니다"
        case .roomNotFound:
            return "채팅방을 찾을 수 없습니다"
        case .messageNotFound:
            return "메시지를 찾을 수 없습니다"
        case .networkError(let message):
            return "네트워크 오류: \(message)"
        }
    }
}

// MARK: - ChatMessageDTO Extension

extension ChatMessageDTO {
    /// ChatMessage로 변환
    func toChatMessage() -> ChatMessage {
        let sender = User(
            userId: self.sender.userId,
            nickname: self.sender.nick,
            profileImageURL: self.sender.profileImage
        )

        return ChatMessage(
            id: self.chatId,
            roomId: self.roomId,
            content: self.content,
            createdAt: ISO8601DateFormatter().date(from: self.createdAt) ?? Date(),
            sender: sender,
            files: self.files
        )
    }
}
