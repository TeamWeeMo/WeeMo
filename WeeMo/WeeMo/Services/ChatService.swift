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
    private let webSocketManager = ChatSocketIOManager.shared

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
            print("Network error, returning cached data: \(error)")
            return realmService.fetchChatRooms()
        }
    }

    /// 특정 채팅방 조회 (로컬)
    func getChatRoom(roomId: String) -> ChatRoom? {
        return realmService.fetchChatRoom(roomId: roomId)
    }

    // MARK: - Chat Message Operations

    /// 채팅 메시지 목록 조회 (로컬 우선, 서버는 최신 동기화용)
    func fetchMessages(roomId: String, cursorDate: String? = nil) async throws -> [ChatMessage] {
        print("ChatService.fetchMessages 시작 - roomId: \(roomId), cursorDate: \(cursorDate ?? "nil")")

        // 1. 먼저 로컬에서 메시지 조회
        let localMessages = realmService.fetchChatMessages(roomId: roomId)
        print("로컬에서 \(localMessages.count)개 메시지 조회")

        // 2. 로컬이 비어있으면 서버에서 즉시 로드
        if localMessages.isEmpty {
            print("로컬이 비어있음 - 서버에서 즉시 로드")
            let serverMessages = try await fetchMessagesFromServer(roomId: roomId)
            print("서버에서 \(serverMessages.count)개 메시지 로드 완료 - fetchMessages 반환")
            return serverMessages
        }

        // 3. 백그라운드에서 서버 최신 메시지 동기화
        Task {
            await syncLatestMessagesFromServer(roomId: roomId)
        }

        print("로컬 메시지 \(localMessages.count)개 반환 - fetchMessages 완료")
        return localMessages
    }

    /// 서버에서 직접 메시지 조회 후 로컬에 저장
    func fetchMessagesFromServer(roomId: String, cursorDate: String? = nil) async throws -> [ChatMessage] {
        print("서버에서 메시지 직접 조회 - roomId: \(roomId)")

        let serverResponse: [ChatMessageDTO]
        do {
            let listResponse = try await networkService.request(
                ChatRouter.fetchMessages(roomId: roomId, cursorDate: cursorDate),
                responseType: ChatMessageListDTO.self
            )
            serverResponse = listResponse.data
        } catch {
            serverResponse = try await networkService.request(
                ChatRouter.fetchMessages(roomId: roomId, cursorDate: cursorDate),
                responseType: [ChatMessageDTO].self
            )
        }

        // 서버에서 받은 메시지를 로컬에 저장
        if !serverResponse.isEmpty {
            try realmService.saveChatMessages(serverResponse)
            print("서버에서 \(serverResponse.count)개 메시지 로드 및 저장 완료")
        }

        let chatMessages = serverResponse.map { $0.toChatMessage() }.sorted { $0.createdAt < $1.createdAt }
        print("fetchMessagesFromServer 반환: \(chatMessages.count)개 메시지")
        return chatMessages
    }

    /// 서버에서 최신 메시지 동기화 (백그라운드)
    private func syncLatestMessagesFromServer(roomId: String) async {
        do {
            // 로컬에서 가장 최근 메시지 시간 조회
            let localMessages = realmService.fetchChatMessages(roomId: roomId)
            let lastMessageDate = localMessages.last?.createdAt
            let cursorDate = lastMessageDate.map { ISO8601DateFormatter().string(from: $0) }

            // 서버에서 최신 메시지들만 조회
            let serverResponse: [ChatMessageDTO]

            do {
                let listResponse = try await networkService.request(
                    ChatRouter.fetchMessages(roomId: roomId, cursorDate: cursorDate),
                    responseType: ChatMessageListDTO.self
                )
                serverResponse = listResponse.data
            } catch {
                // 배열 형태로 재시도
                serverResponse = try await networkService.request(
                    ChatRouter.fetchMessages(roomId: roomId, cursorDate: cursorDate),
                    responseType: [ChatMessageDTO].self
                )
            }

            // 새로운 메시지만 로컬에 저장
            if !serverResponse.isEmpty {
                let newMessages = serverResponse.filter { dto in
                    !localMessages.contains { $0.id == dto.chatId }
                }

                if !newMessages.isEmpty {
                    try realmService.saveChatMessages(newMessages)
                    print("서버에서 \(newMessages.count)개 새 메시지 동기화 완료")
                }
            }
        } catch {
            print("서버 메시지 동기화 실패: \(error)")
        }
    }

    /// 메시지 전송 (즉시 로컬 저장 + 소켓 전송)
    func sendMessage(roomId: String, content: String, files: [String]? = nil) async throws -> ChatMessage {
        guard let currentUser = getCurrentUser() else {
            throw ChatError.userNotFound
        }

        do {
            print("ChatService.sendMessage 시작!")

            // 1. 서버로 메시지 전송
            let response = try await networkService.request(
                ChatRouter.sendMessage(roomId: roomId, content: content, files: files),
                responseType: ChatMessageDTO.self
            )
            print("서버 응답 받음: \(response.chatId)")

            let chatMessage = response.toChatMessage()

            // 2. 즉시 로컬에 저장
            try realmService.saveChatMessage(response)
            print("메시진 로컬 저장 완료")

            // 3. 소켓으로 실시간 전송 (다른 사용자에게 알림)
            webSocketManager.sendMessage(roomId: roomId, content: content, files: files)
            print("Socket.IO 전송 완료")

            print("ChatService.sendMessage 완료!")
            return chatMessage

        } catch {
            print("ChatService.sendMessage 실패: \(error)")
            throw error
        }
    }

    /// 로컬 메시지 목록 조회 (실시간 업데이트용)
    func getLocalMessages(roomId: String, limit: Int? = nil) -> [ChatMessage] {
        return realmService.fetchChatMessages(roomId: roomId, limit: limit)
    }

    /// 더 이전 메시지 로드 (로컬 우선)
    func loadMoreMessages(roomId: String, beforeMessageId: String, limit: Int = 50) async throws -> [ChatMessage] {
        print("이전 메시지 로드 - roomId: \(roomId), beforeMessageId: \(beforeMessageId)")

        // 1. 먼저 로컬에서 이전 메시지 조회
        let localMoreMessages = realmService.fetchRecentMessages(
            roomId: roomId,
            before: beforeMessageId,
            limit: limit
        )

        if !localMoreMessages.isEmpty {
            print("로컬에서 \(localMoreMessages.count)개 이전 메시지 조회")
            return localMoreMessages
        }

        // 2. 로컬에 없으면 서버에서 조회 후 로컬에 저장
        do {
            print("로컬에 없음, 서버에서 조회 중...")

            let localMessages = realmService.fetchChatMessages(roomId: roomId)
            guard let beforeMessage = localMessages.first(where: { $0.id == beforeMessageId }) else {
                print("기준 메시지를 찾을 수 없음")
                return []
            }

            let cursorDate = ISO8601DateFormatter().string(from: beforeMessage.createdAt)

            // 서버에서 이전 메시지 조회
            let serverResponse: [ChatMessageDTO]
            do {
                let response = try await networkService.request(
                    ChatRouter.fetchMessages(roomId: roomId, cursorDate: cursorDate),
                    responseType: ChatMessageListDTO.self
                )
                serverResponse = response.data
            } catch {
                let response = try await networkService.request(
                    ChatRouter.fetchMessages(roomId: roomId, cursorDate: cursorDate),
                    responseType: [ChatMessageDTO].self
                )
                serverResponse = response
            }

            if !serverResponse.isEmpty {
                // 서버에서 받은 메시지를 로컬에 저장
                try realmService.saveChatMessages(serverResponse)
                print("서버에서 \(serverResponse.count)개 이전 메시지를 로컬에 저장")

                return serverResponse.map { $0.toChatMessage() }
            }

            return []

        } catch {
            print("서버에서 이전 메시지 로드 실패: \(error)")
            throw error
        }
    }

    // MARK: - File Upload

    /// 채팅 파일 업로드
    func uploadChatFiles(roomId: String, files: [Data]) async throws -> [String] {
        guard !files.isEmpty else {
            print("업로드할 파일이 없습니다")
            return []
        }

        print("파일 업로드 시작: \(files.count)개 파일, roomId: \(roomId)")

        do {
            let response = try await networkService.uploadMedia(
                ChatRouter.uploadChatFiles(roomId: roomId, files: files),
                mediaFiles: files,
                responseType: FileDTO.self
            )

            print("파일 업로드 성공: \(response.files)")
            return response.files

        } catch {
            print("파일 업로드 실패: \(error)")
            throw error
        }
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

        // 날짜 파싱 개선
        let parsedDate = parseDate(from: self.createdAt)

        return ChatMessage(
            id: self.chatId,
            roomId: self.roomId,
            content: self.content,
            createdAt: parsedDate,
            sender: sender,
            files: self.files
        )
    }

    /// 다양한 날짜 형식을 지원하는 파싱 함수
    private func parseDate(from dateString: String) -> Date {
        // ISO8601 먼저 시도
        if let date = ISO8601DateFormatter().date(from: dateString) {
            return date
        }

        print("기본 ISO8601 파싱 실패: '\(dateString)' - 다른 포맷 시도")

        // 다른 가능한 포맷들
        let formatters: [(String, TimeZone?)] = [
            ("yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'", TimeZone(secondsFromGMT: 0)),
            ("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", TimeZone(secondsFromGMT: 0)),
            ("yyyy-MM-dd'T'HH:mm:ss'Z'", TimeZone(secondsFromGMT: 0)),
            ("yyyy-MM-dd HH:mm:ss", nil),
            ("yyyy-MM-dd'T'HH:mm:ss.SSSSSS", nil),
            ("yyyy-MM-dd'T'HH:mm:ss.SSS", nil),
            ("yyyy-MM-dd'T'HH:mm:ss", nil)
        ]

        for (format, timeZone) in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let tz = timeZone {
                formatter.timeZone = tz
            }
            if let date = formatter.date(from: dateString) {
                print("성공한 포맷: \(format) -> \(date)")
                return date
            }
        }

        print("모든 날짜 포맷 파싱 실패: '\(dateString)' - 현재 시간 사용")
        return Date()
    }
}
