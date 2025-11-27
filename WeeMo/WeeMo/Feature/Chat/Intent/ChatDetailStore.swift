//
//  ChatDetailStore.swift
//  WeeMo
//
//  Created by 차지용 on 11/24/25.
//

import Foundation
import Combine

final class ChatDetailStore: ObservableObject {
    @Published var state: ChatDetailState

    private let chatService = ChatService.shared
    private let socketManager = ChatSocketIOManager.shared
    private var cancellables = Set<AnyCancellable>()

    init(room: ChatRoom) {
        self.state = ChatDetailState(room: room)
        setupSocketListeners()
    }

    deinit {
        handle(.closeSocketConnection)
    }

    func handle(_ intent: ChatDetailIntent) {
        switch intent {
        case .loadMessages(let roomId):
            loadMessages(roomId: roomId)
        case .sendMessage(let content, let files):
            sendMessage(content: content, files: files)
        case .setupSocketConnection(let roomId):
            setupSocketConnection(roomId: roomId)
        case .closeSocketConnection:
            closeSocketConnection()
        case .loadMoreMessages(let beforeMessageId):
            loadMoreMessages(beforeMessageId: beforeMessageId)
        case .retryLoadMessages:
            loadMessages(roomId: state.room.id)
        case .showCamera:
            showCamera()
        case .sendCameraPhoto(let data):
            sendCameraPhoto(data: data)
        case .showVoiceRecorder:
            showVoiceRecorder()
        case .sendVoiceRecording(let data):
            sendVoiceRecording(data: data)
        }
    }

    // MARK: - Socket Setup

    private func setupSocketListeners() {
        // 새 메시지 수신 - 메인 스레드에서 직접 처리
        socketManager.chatMessageSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self else { return }
                Task { @MainActor in
                    await self.handleReceivedMessage(message)
                }
            }
            .store(in: &cancellables)

        // 연결 상태 모니터링
        socketManager.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.state.isSocketConnected = isConnected
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func handleReceivedMessage(_ newMessage: ChatMessage) async {
        print("📨 Store에서 새 메시지 수신: \(newMessage.content)")

        // 현재 채팅방과 메시지 채팅방 일치 확인
        guard newMessage.roomId == state.room.id else {
            print("🔄 다른 채팅방 메시지 무시: \(newMessage.roomId) vs \(state.room.id)")
            return
        }

        // 중복 메시지 체크 (ID만 확인)
        guard !state.messages.contains(where: { $0.id == newMessage.id }) else {
            print("🔄 중복 메시지 무시: \(newMessage.id)")
            return
        }

        // 새 메시지 추가
        state.messages.append(newMessage)
        state.messages.sort { $0.createdAt < $1.createdAt }
        state.shouldScrollToBottom = true

        // 강제 UI 업데이트
        objectWillChange.send()

        print("✅ 새 메시지 추가됨: \(newMessage.content) | 총 메시지 수: \(state.messages.count)")


        // 30일 정책에 따른 로컬 DB 저장 (백그라운드)
        Task.detached {
            await self.saveMessageToLocal(newMessage)
        }
    }

    // MARK: - Message Loading

    private func loadMessages(roomId: String) {
        state.isLoading = true
        state.errorMessage = nil

        Task {
            do {
                let calendar = Calendar.current
                let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()

                // 1. 30일 이전 메시지는 Realm에서 로드
                let localOldMessages = chatService.getLocalMessages(roomId: roomId).filter {
                    $0.createdAt <= thirtyDaysAgo
                }

                await MainActor.run {
                    state.messages = localOldMessages
                    print("📱 Realm에서 30일 이전 메시지 \(localOldMessages.count)개 로드")
                }

                // 2. 30일 이후(최근) 메시지는 서버에서 조회
                let recentServerMessages = try await chatService.fetchMessages(
                    roomId: roomId,
                    cursorDate: nil // 모든 메시지 조회 후 필터링
                )

                await MainActor.run {
                    // 30일 이후(최근) 메시지만 필터링
                    let recentMessages = recentServerMessages.filter { $0.createdAt > thirtyDaysAgo }

                    // Realm(30일 이전) + 서버(30일 이후) 메시지 병합
                    var finalMessages = localOldMessages
                    finalMessages.append(contentsOf: recentMessages)

                    // 시간순 정렬 (오래된 것부터)
                    finalMessages.sort { $0.createdAt < $1.createdAt }

                    state.messages = finalMessages
                    state.shouldScrollToBottom = true
                    state.isLoading = false

                    print("✅ 메시지 로드 완료: Realm(30일 이전) \(localOldMessages.count)개 + 서버(30일 이후) \(recentMessages.count)개 = 총 \(finalMessages.count)개")
                }

            } catch {
                await MainActor.run {
                    state.errorMessage = "메시지를 불러오는데 실패했습니다: \(error.localizedDescription)"
                    state.isLoading = false
                    print("❌ 메시지 로드 실패: \(error)")
                }
            }
        }
    }

    // 로컬과 서버의 오래된 메시지 병합 (중복 제거)
    private func mergeOldMessages(local: [ChatMessage], server: [ChatMessage]) -> [ChatMessage] {
        var merged = local

        for serverMessage in server {
            if !merged.contains(where: { $0.id == serverMessage.id }) {
                merged.append(serverMessage)
            }
        }

        return merged.sorted { $0.createdAt < $1.createdAt }
    }

    private func loadMoreMessages(beforeMessageId: String) {
        guard !state.isLoadingMore && state.hasMoreMessages else { return }

        state.isLoadingMore = true

        Task {
            do {
                let moreMessages = try await chatService.loadMoreMessages(
                    roomId: state.room.id,
                    beforeMessageId: beforeMessageId,
                    limit: 50
                )

                await MainActor.run {
                    if moreMessages.isEmpty {
                        state.hasMoreMessages = false
                        print("📭 더 이상 불러올 메시지가 없음")
                    } else {
                        // 스크롤 위치 유지를 위해 현재 첫 번째 메시지 ID 저장
                        let currentFirstMessageId = state.messages.first?.id

                        // 기존 메시지 앞에 추가
                        state.messages.insert(contentsOf: moreMessages, at: 0)

                        // 스크롤 위치 유지를 위해 shouldScrollToBottom을 false로 설정
                        state.shouldScrollToBottom = false

                        print("✅ 이전 메시지 \(moreMessages.count)개 로드 (스크롤 위치 유지)")
                    }
                    state.isLoadingMore = false
                }

            } catch {
                await MainActor.run {
                    state.isLoadingMore = false
                    print("❌ 이전 메시지 로드 실패: \(error)")
                }
            }
        }
    }

    // MARK: - Message Sending

    private func sendMessage(content: String, files: [String]?) {
        let messageContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        // 텍스트와 파일이 모두 비어있으면 전송하지 않음
        guard !messageContent.isEmpty || (files != nil && !files!.isEmpty) else { return }

        state.inputText = "" // 입력창 즉시 클리어
        state.isSendingMessage = true

        // 임시 메시지는 추가하지 않음 - 소켓에서만 메시지 추가
        Task {
            do {
                let sentMessage = try await chatService.sendMessage(
                    roomId: state.room.id,
                    content: messageContent,
                    files: files
                )

                await MainActor.run {
                    state.isSendingMessage = false
                    print("✅ 메시지 전송 성공: \(sentMessage.content)")
                    // 소켓에서 메시지를 받아서 화면에 표시됨
                }

            } catch {
                await MainActor.run {
                    state.errorMessage = "메시지 전송에 실패했습니다: \(error.localizedDescription)"
                    state.isSendingMessage = false
                    print("❌ 메시지 전송 실패: \(error)")
                }
            }
        }
    }

    // MARK: - Socket Connection

    private func setupSocketConnection(roomId: String) {
        socketManager.openWebSocket(roomId: roomId)
    }

    private func closeSocketConnection() {
        socketManager.closeWebSocket()
    }

    // MARK: - Helper Methods

    private func createTempMessage(content: String, files: [String]?) -> ChatMessage {
        let currentUser = User(
            userId: state.currentUserId,
            nickname: "나", // 임시로 고정값 사용
            profileImageURL: nil
        )

        return ChatMessage(
            id: "temp-\(UUID().uuidString)",
            roomId: state.room.id,
            content: content,
            createdAt: Date(),
            sender: currentUser,
            files: files ?? []
        )
    }

    private func getLastMessageDate() -> String? {
        guard let lastMessage = state.messages.last else { return nil }
        return ISO8601DateFormatter().string(from: lastMessage.createdAt)
    }

    private func saveMessageToLocal(_ message: ChatMessage) async {
        // 모든 새로운 메시지를 Realm에 저장
        // (30일이 지나면 자동으로 정리됨)

        // ChatRealmService를 통한 저장
        do {
            let messageDTO = ChatMessageDTO(
                chatId: message.id,
                roomId: message.roomId,
                content: message.content,
                createdAt: ISO8601DateFormatter().string(from: message.createdAt),
                sender: UserDTO(
                    userId: message.sender.userId,
                    nick: message.sender.nickname,
                    profileImage: message.sender.profileImageURL
                ),
                files: message.files
            )

            try ChatRealmService.shared.saveChatMessage(messageDTO)
            print("✅ 새 메시지 Realm에 저장 완료: \(message.content)")
        } catch {
            print("❌ Realm 저장 실패: \(error)")
        }
    }


    // MARK: - Cleanup Methods

    /// 30일 이후(최근) 메시지를 Realm에서 정리 (앱 시작 시 호출)
    /// 30일 정책: 30일 이전 메시지는 Realm 저장, 30일 이후(최근) 메시지는 서버에서만 관리
    func cleanupRecentMessages() {
        Task {
            let calendar = Calendar.current
            let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()

            do {
                // 30일 이후(최근) 메시지들을 Realm에서 삭제 (서버에서 관리하므로)
                try ChatRealmService.shared.deleteMessagesAfter(date: thirtyDaysAgo, roomId: state.room.id)
                print("✅ 30일 이후(최근) 메시지 Realm에서 정리 완료 (서버에서 관리)")
            } catch {
                print("❌ 30일 이후 메시지 정리 실패: \(error)")
            }
        }
    }

    // MARK: - Camera Methods

    private func showCamera() {
        state.showPlusMenu = false
        state.showCamera = true
    }

    private func sendCameraPhoto(data: Data) {
        Task {
            await MainActor.run {
                state.isSendingMessage = true
            }

            do {
                // 파일 업로드
                let fileUrls = try await chatService.uploadChatFiles(
                    roomId: state.room.id,
                    files: [data]
                )

                // 메시지 전송
                if let firstFileUrl = fileUrls.first {
                    try await chatService.sendMessage(
                        roomId: state.room.id,
                        content: "",
                        files: [firstFileUrl]
                    )
                }

                await MainActor.run {
                    state.isSendingMessage = false
                    state.showCamera = false
                    print("카메라 사진 전송 성공")
                }

            } catch {
                await MainActor.run {
                    state.isSendingMessage = false
                    state.showCamera = false
                    state.errorMessage = "사진 전송에 실패했습니다: \(error.localizedDescription)"
                    print("카메라 사진 전송 실패: \(error)")
                }
            }
        }
    }

    // MARK: - Voice Recording Methods

    private func showVoiceRecorder() {
        state.showPlusMenu = false
        state.showVoiceRecorder = true
    }

    private func sendVoiceRecording(data: Data) {
        Task {
            await MainActor.run {
                state.isSendingMessage = true
            }

            do {
                // 음성 파일 업로드
                let fileUrls = try await chatService.uploadChatFiles(
                    roomId: state.room.id,
                    files: [data]
                )

                // 메시지 전송
                if let firstFileUrl = fileUrls.first {
                    try await chatService.sendMessage(
                        roomId: state.room.id,
                        content: "",
                        files: [firstFileUrl]
                    )
                }

                await MainActor.run {
                    state.isSendingMessage = false
                    state.showVoiceRecorder = false
                    print("음성 메시지 전송 성공")
                }

            } catch {
                await MainActor.run {
                    state.isSendingMessage = false
                    state.showVoiceRecorder = false
                    state.errorMessage = "음성 전송에 실패했습니다: \(error.localizedDescription)"
                    print("음성 메시지 전송 실패: \(error)")
                }
            }
        }
    }
}
