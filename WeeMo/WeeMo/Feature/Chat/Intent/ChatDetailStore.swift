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

        // 통합된 중복 처리 함수 사용
        addMessageWithDeduplication(newMessage)

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
                // 로컬 메시지가 있으면 즉시 로딩 완료 처리
                state.isLoading = false
                state.shouldScrollToBottom = true
                objectWillChange.send()
                print("로컬 메시지 \(localMessages.count)개 즉시 표시 - 전체 로딩 완료")
            }
        } else {
            print("로컬 메시지 없음 - 서버 응답 대기 중 (전체 화면 로딩 유지)")
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
                        // 새 메시지 동기화: 스크롤을 하단으로 이동
                        for message in fetchedMessages {
                            addMessageWithDeduplication(message, shouldAutoScroll: true)
                        }
                        print("서버 동기화: 새 메시지 처리 완료")
                    } else {
                        // 초기 로드: 자동 스크롤을 활성화하여 최신 메시지로 이동
                        for message in fetchedMessages {
                            addMessageWithDeduplication(message, shouldAutoScroll: true)
                        }
                        print("초기 로드: 서버 메시지로 초기화")
                    }

                    // 로컬이 비어있던 경우에만 로딩 완료 처리 (로컬이 있으면 이미 완료됨)
                    if state.isLoading {
                        state.isLoading = false
                        print("초기 로드 완료 - 전체 화면 로딩 인디케이터 제거")
                    }
                    objectWillChange.send()
                    print("서버 동기화 UI 업데이트 완료")
                }

            } catch {
                await MainActor.run {
                    state.errorMessage = "메시지를 불러오는데 실패했습니다: \(error.localizedDescription)"
                    // 에러 발생 시 로딩 상태 정리
                    state.isLoading = false
                    print("서버 동기화 실패: \(error) - 로딩 상태 정리")
                }
            }
        }
    }


    private func loadMoreMessages(beforeMessageId: String) {
        guard !state.isLoadingMore && state.hasMoreMessages else { return }

        state.isLoadingMore = true
        print("이전 메시지 로드 시작 - 현재 위치 유지")

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
                        // 이전 메시지 로드: 현재 위치 유지 (shouldAutoScroll = false)
                        for message in moreMessages {
                            addMessageWithDeduplication(message, shouldAutoScroll: false)
                        }
                        print("이전 메시지 \(moreMessages.count)개 로드 완료 - 스크롤 위치 유지")
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
                    // 통합된 중복 처리 함수 사용
                    addMessageWithDeduplication(sentMessage)

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

    // 중복 처리가 필요한 케이스:
    // 1. Socket으로 먼저 수신 → API 응답에도 동일 메시지 포함
    // 2. API 응답 처리 중 → Socket으로 새 메시지 수신
    // 해결: chat_id 기반 중복 체크
    private func addMessageWithDeduplication(_ newMessage: ChatMessage, shouldAutoScroll: Bool = true) {
        // 이미 존재하는 메시지인지 확인
        guard !state.messages.contains(where: { $0.id == newMessage.id }) else {
            print("중복 메시지 무시: \(newMessage.id)")
            return
        }

        state.messages.append(newMessage)
        // 메시지 순서 보장: 항상 createdAt 기준 정렬
        state.messages.sort { $0.createdAt < $1.createdAt }

        // 스크롤 UX: 새 메시지만 자동 스크롤, 이전 메시지는 위치 유지
        if shouldAutoScroll {
            state.shouldScrollToBottom = true
        }

        print("새 메시지 추가 완료: \(newMessage.content)")

        // UI 업데이트 보장
        objectWillChange.send()
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
