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

    /// 채팅 메시지 목록 조회 (30일 정책: 최근 메시지는 서버, 오래된 메시지는 로컬)
    func fetchMessages(roomId: String, cursorDate: String? = nil) async throws -> [ChatMessage] {
        print("fetchMessages 시작 - roomId: \(roomId), cursorDate: \(cursorDate ?? "nil")")

        do {
            // 먼저 딕셔너리 형태(ChatMessageListDTO)로 시도
            let listResponse = try await networkService.request(
                ChatRouter.fetchMessages(roomId: roomId, cursorDate: cursorDate),
                responseType: ChatMessageListDTO.self
            )

            print("딕셔너리 형태로 서버에서 \(listResponse.data.count)개 메시지 받음")
            return processChatMessages(listResponse.data, roomId: roomId)

        } catch {
            print("딕셔너리 형태 실패, 배열 형태로 재시도: \(error)")

            do {
                // 배열 형태로 재시도
                let arrayResponse = try await networkService.request(
                    ChatRouter.fetchMessages(roomId: roomId, cursorDate: cursorDate),
                    responseType: [ChatMessageDTO].self
                )

                print("배열 형태로 서버에서 \(arrayResponse.count)개 메시지 받음")
                return processChatMessages(arrayResponse, roomId: roomId)

            } catch {
                // 네트워크 오류시 로컬 데이터 반환
                print("Network error, returning cached messages: \(error)")
                return realmService.fetchChatMessages(roomId: roomId)
            }
        }
    }

    /// 메시지 처리 공통 로직
    private func processChatMessages(_ messageDTOs: [ChatMessageDTO], roomId: String) -> [ChatMessage] {
        // 30일 기준 날짜
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        // 서버에서 받은 메시지를 30일 기준으로 분리
        let serverMessages = messageDTOs.map { $0.toChatMessage() }
        let oldMessages = serverMessages.filter { $0.createdAt <= thirtyDaysAgo }

        // 30일 이후 메시지만 Realm에 저장
        if !oldMessages.isEmpty {
            let oldMessageDTOs = messageDTOs.filter {
                let messageDate = ISO8601DateFormatter().date(from: $0.createdAt) ?? Date()
                return messageDate <= thirtyDaysAgo
            }
            do {
                try realmService.saveChatMessages(oldMessageDTOs)
                print("30일+ 이전 메시지 \(oldMessageDTOs.count)개 Realm에 저장")
            } catch {
                print("Realm 저장 실패: \(error)")
            }
        }

        print("메시지 처리 완료 - 전체: \(serverMessages.count)개, 30일+ 이전: \(oldMessages.count)개")

        // 서버에서 받은 메시지 그대로 반환 (30일 이내는 서버 데이터 우선)
        return serverMessages
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
            print("ChatService.sendMessage 시작!")

            // 2. 서버로 메시지 전송
            let response = try await networkService.request(
                ChatRouter.sendMessage(roomId: roomId, content: content, files: files),
                responseType: ChatMessageDTO.self
            )
            print("서버 응답 받음: \(response.chatId)")

            let chatMessage = response.toChatMessage()

            // 3. Realm 작업을 백그라운드에서 처리
            Task.detached(priority: .background) {
                do {
                    try await Task.sleep(nanoseconds: 100_000_000) // 100ms 지연
                    try self.realmService.deleteTempMessage(tempId: tempMessageId)
                    try self.realmService.saveChatMessage(response)
                } catch {
                    print("Realm 업데이트 실패: \(error)")
                }
            }

            // 4. 웹소켓으로 실시간 전송 (선택적)
            webSocketManager.sendMessage(roomId: roomId, content: content, files: files)
            print("Socket.IO 전송 완료")

            print("ChatMessage 생성 완료: \(chatMessage.id) - \(chatMessage.content)")

            // 5. 즉시 UI 업데이트를 위해 Socket.IO Subject에 메시지 전송
            print("즉시 UI 업데이트 시작...")
            DispatchQueue.main.async {
                print("메인 스레드에서 Subject.send 호출")
                self.webSocketManager.chatMessageSubject.send(chatMessage)
                print("즉시 UI 업데이트 완료: \(chatMessage.content)")
            }
            print("ChatService.sendMessage 완료!")

            return chatMessage

        } catch {
            // 5. 전송 실패시 임시 메시지 삭제 (백그라운드에서 처리)
            Task.detached(priority: .background) {
                do {
                    try self.realmService.deleteTempMessage(tempId: tempMessageId)
                } catch {
                    print("임시 메시지 삭제 실패: \(error)")
                }
            }
            throw error
        }
    }

    /// 로컬 메시지 목록 조회 (실시간 업데이트용)
    func getLocalMessages(roomId: String, limit: Int? = nil) -> [ChatMessage] {
        return realmService.fetchChatMessages(roomId: roomId, limit: limit)
    }

    /// 더 이전 메시지 로드 (30일 정책 적용)
    func loadMoreMessages(roomId: String, beforeMessageId: String, limit: Int = 50) async throws -> [ChatMessage] {
        // 30일 기준 날짜
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        // 로컬에서 해당 메시지의 날짜 찾기
        let localMessages = realmService.fetchChatMessages(roomId: roomId)
        guard let beforeMessage = localMessages.first(where: { $0.id == beforeMessageId }) else {
            return []
        }

        // 메시지가 30일 이후인지 확인
        if beforeMessage.createdAt <= thirtyDaysAgo {
            // 30일 이후 메시지는 로컬에서만 조회
            print("30일 이후 메시지 - 로컬에서 조회")
            return realmService.fetchRecentMessages(roomId: roomId, before: beforeMessageId, limit: limit)
        } else {
            // 30일 이내 메시지는 서버에서 조회
            let cursorDate = ISO8601DateFormatter().string(from: beforeMessage.createdAt)

            print("이전 메시지 로드 - roomId: \(roomId), cursorDate: \(cursorDate)")
            print("beforeMessage 날짜: \(beforeMessage.createdAt), ID: \(beforeMessage.id)")

            do {
                // 서버 응답이 딕셔너리일 가능성을 고려하여 ChatMessageListDTO로 시도
                print("서버에서 이전 메시지 조회 중...")
                let response = try await networkService.request(
                    ChatRouter.fetchMessages(roomId: roomId, cursorDate: cursorDate),
                    responseType: ChatMessageListDTO.self
                )

                print("서버에서 \(response.data.count)개 이전 메시지 받음")

                // 30일 기준으로 분리
                let serverMessages = response.data.map { $0.toChatMessage() }
                let oldMessages = serverMessages.filter { $0.createdAt <= thirtyDaysAgo }

                // 30일 이후 메시지만 Realm에 저장
                if !oldMessages.isEmpty {
                    let oldMessageDTOs = response.data.filter {
                        let messageDate = ISO8601DateFormatter().date(from: $0.createdAt) ?? Date()
                        return messageDate <= thirtyDaysAgo
                    }
                    try realmService.saveChatMessages(oldMessageDTOs)
                }

                return serverMessages

            } catch {
                // 배열 형식으로 다시 시도
                print("ChatMessageListDTO 실패, 배열 형식으로 재시도: \(error)")
                do {
                    let response = try await networkService.request(
                        ChatRouter.fetchMessages(roomId: roomId, cursorDate: cursorDate),
                        responseType: [ChatMessageDTO].self
                    )

                    print("배열 형식으로 서버에서 \(response.count)개 이전 메시지 받음")

                    let serverMessages = response.map { $0.toChatMessage() }
                    let oldMessages = serverMessages.filter { $0.createdAt <= thirtyDaysAgo }

                    // 30일 이후 메시지만 Realm에 저장
                    if !oldMessages.isEmpty {
                        let oldMessageDTOs = response.filter {
                            let messageDate = ISO8601DateFormatter().date(from: $0.createdAt) ?? Date()
                            return messageDate <= thirtyDaysAgo
                        }
                        try realmService.saveChatMessages(oldMessageDTOs)
                        print("30일+ 이전 메시지 \(oldMessageDTOs.count)개 Realm에 저장")
                    }

                    return serverMessages
                } catch let networkError {
                    print("서버에서 이전 메시지 로드 완전 실패: \(networkError)")
                    throw networkError
                }
            }
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
