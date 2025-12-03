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
        print("Store에서 새 메시지 수신: \(newMessage.content)")

        // 현재 채팅방과 메시지 채팅방 일치 확인
        guard newMessage.roomId == state.room.id else {
            print("다른 채팅방 메시지 무시: \(newMessage.roomId) vs \(state.room.id)")
            return
        }

        // 중복 메시지 체크 (ID만 확인)
        guard !state.messages.contains(where: { $0.id == newMessage.id }) else {
            print("중복 메시지 무시: \(newMessage.id)")
            return
        }

        // 자신이 방금 보낸 메시지인 경우 추가 확인 (시간 기반)
        let currentUserId = state.currentUserId
        if newMessage.sender.userId == currentUserId {
            // 최근 5초 이내에 보낸 동일한 내용의 메시지가 있는지 확인
            let recentMessages = state.messages.filter {
                $0.sender.userId == currentUserId &&
                abs($0.createdAt.timeIntervalSince(newMessage.createdAt)) < 5 &&
                $0.content == newMessage.content
            }
            if !recentMessages.isEmpty {
                print("최근 보낸 동일 메시지 무시: \(newMessage.content)")
                return
            }
        }

        // 새 메시지 추가
        state.messages.append(newMessage)
        state.messages.sort { $0.createdAt < $1.createdAt }
        print("새 메시지 추가 완료: \(newMessage.content)")
        state.shouldScrollToBottom = true

        // 강제 UI 업데이트
        objectWillChange.send()

        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        print("새 메시지 추가됨: \(newMessage.content) | 시간: \(formatter.string(from: newMessage.createdAt)) | 총 메시지 수: \(state.messages.count)")

        // 마지막 몇 개 메시지 확인
        let lastFew = state.messages.suffix(3)
        for (index, message) in lastFew.enumerated() {
            print("  마지막[\(index)]: \(formatter.string(from: message.createdAt)) - \(message.content)")
        }


        // 소켓 메시지를 로컬에 즉시 저장 (백그라운드)
        Task.detached {
            await self.saveMessageToLocal(newMessage)
        }
    }

    // MARK: - Message Loading

    private func loadMessages(roomId: String) {
        state.isLoading = true
        state.errorMessage = nil
        print("ChatDetailStore.loadMessages 시작 - roomId: \(roomId)")

        // 1. 먼저 로컬 DB에서 메시지 로드
        let localMessages = chatService.getLocalMessages(roomId: roomId)

        // 2. 로컬 메시지가 있으면 즉시 UI 업데이트
        if !localMessages.isEmpty {
            Task { @MainActor in
                let sortedMessages = localMessages.sorted { $0.createdAt < $1.createdAt }
                state.messages = sortedMessages
                state.isLoading = false
                state.shouldScrollToBottom = true
                objectWillChange.send()
                print("로컬 메시지 \(localMessages.count)개 즉시 표시")
            }
        } else {
            print("로컬 메시지 없음 - 서버 응답 대기 중")
        }

        // 3. 즉시 Socket 연결 (메시지 유실 방지)
        setupSocketConnection(roomId: roomId)

        // 4. 백그라운드에서 서버 동기화
        Task {
            do {
                print("ChatService.fetchMessages 호출 전")
                let fetchedMessages = try await chatService.fetchMessages(roomId: roomId)
                print("ChatService.fetchMessages 응답: \(fetchedMessages.count)개 메시지")

                await MainActor.run {
                    print("서버 동기화 완료 - UI 업데이트 시작")

                    // 현재 state에 메시지가 있다면 (로컬에서 이미 로드함) 새로운 메시지만 추가
                    if !state.messages.isEmpty {
                        let existingIds = Set(state.messages.map { $0.id })
                        let newMessages = fetchedMessages.filter { !existingIds.contains($0.id) }

                        if !newMessages.isEmpty {
                            state.messages.append(contentsOf: newMessages)
                            state.messages.sort { $0.createdAt < $1.createdAt }
                            print("서버에서 새로운 메시지 \(newMessages.count)개 추가")
                            state.shouldScrollToBottom = true
                        } else {
                            print("서버 동기화: 새로운 메시지 없음")
                        }
                    } else {
                        // 로컬이 비어있던 경우에만 전체 교체
                        let sortedMessages = fetchedMessages.sorted { $0.createdAt < $1.createdAt }
                        state.messages = sortedMessages
                        print("로컬이 비어있어서 서버 메시지 \(sortedMessages.count)개로 전체 교체")

                        if !sortedMessages.isEmpty {
                            state.shouldScrollToBottom = true
                        }
                    }

                    state.isLoading = false
                    objectWillChange.send()
                    print("서버 동기화 UI 업데이트 완료")
                }

            } catch {
                await MainActor.run {
                    state.errorMessage = "메시지를 불러오는데 실패했습니다: \(error.localizedDescription)"
                    state.isLoading = false
                    print("메시지 로드 실패: \(error)")
                }
            }
        }
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
                        print("더 이상 불러올 메시지가 없음")
                    } else {
                        // 스크롤 위치 유지를 위해 현재 첫 번째 메시지 ID 저장
                        let currentFirstMessageId = state.messages.first?.id

                        // 중복 제거: 이미 존재하는 메시지는 제외
                        let existingIds = Set(state.messages.map { $0.id })
                        let uniqueNewMessages = moreMessages.filter { !existingIds.contains($0.id) }

                        if !uniqueNewMessages.isEmpty {
                            // 기존 메시지 앞에 중복되지 않는 메시지만 추가
                            state.messages.insert(contentsOf: uniqueNewMessages, at: 0)
                            print("이전 메시지 \(uniqueNewMessages.count)개 로드 (중복 \(moreMessages.count - uniqueNewMessages.count)개 제외)")
                        } else {
                            print("모든 이전 메시지가 중복됨")
                        }

                        // 스크롤 위치 유지를 위해 shouldScrollToBottom을 false로 설정
                        state.shouldScrollToBottom = false
                    }
                    state.isLoadingMore = false
                }

            } catch {
                await MainActor.run {
                    state.isLoadingMore = false
                    print("이전 메시지 로드 실패: \(error)")
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

        // 전송 후 즉시 UI 업데이트
        Task {
            do {
                let sentMessage = try await chatService.sendMessage(
                    roomId: state.room.id,
                    content: messageContent,
                    files: files
                )

                await MainActor.run {
                    // 중복 방지 - ID와 내용으로 이중 체크
                    let isDuplicate = state.messages.contains { existingMessage in
                        existingMessage.id == sentMessage.id ||
                        (existingMessage.content == sentMessage.content &&
                         existingMessage.sender.userId == sentMessage.sender.userId &&
                         abs(existingMessage.createdAt.timeIntervalSince(sentMessage.createdAt)) < 2)
                    }

                    if !isDuplicate {
                        state.messages.append(sentMessage)
                        state.messages.sort { $0.createdAt < $1.createdAt }
                        state.shouldScrollToBottom = true
                        print("전송한 메시지 UI에 추가: \(sentMessage.content)")
                    } else {
                        print("전송한 메시지 중복 무시: \(sentMessage.content)")
                    }

                    state.isSendingMessage = false
                    print("메시지 전송 성공: \(sentMessage.content)")
                }

            } catch {
                await MainActor.run {
                    state.errorMessage = "메시지 전송에 실패했습니다: \(error.localizedDescription)"
                    state.isSendingMessage = false
                    print("메시지 전송 실패: \(error)")
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
            print("새 메시지 Realm에 저장 완료: \(message.content)")
        } catch {
            print("Realm 저장 실패: \(error)")
        }
    }


    // MARK: - Cleanup Methods


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
