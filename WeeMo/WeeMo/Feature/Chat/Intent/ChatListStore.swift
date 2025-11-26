//
//  ChatListStore.swift
//  WeeMo
//
//  Created by 차지용 on 11/24/25.
//

import Foundation
import Combine

final class ChatListStore: ObservableObject {
    @Published var state = ChatListState()

    private let networkService = NetworkService()
    private let socketManager = ChatSocketIOManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 소켓 리스너는 ChatListView에서 수동으로 설정
    }

    deinit {
        handle(.cleanupSocketListeners)
    }

    func handle(_ intent: ChatListIntent) {
        switch intent {
        case .loadChatRooms:
            loadChatRooms()
        case .refreshChatRooms:
            refreshChatRooms()
        case .retryLoadChatRooms:
            retryLoadChatRooms()
        case .selectChatRoom(let room):
            selectChatRoom(room)
        case .setupSocketListeners:
            setupSocketListeners()
        case .cleanupSocketListeners:
            cleanupSocketListeners()
        }
    }

    // MARK: - Socket Setup

    private func setupSocketListeners() {
        guard !state.isSocketListening else { return }

        // 채팅방 리스트 업데이트 수신
        socketManager.chatRoomUpdateSubject
            .sink { [weak self] roomId in
                Task { @MainActor in
                    print("🔄 채팅방 리스트 업데이트 신호 수신: \(roomId)")
                    self?.handle(.refreshChatRooms)
                }
            }
            .store(in: &cancellables)

        state.isSocketListening = true
        print("✅ ChatList Socket 리스너 설정 완료")
    }

    private func cleanupSocketListeners() {
        cancellables.removeAll()
        state.isSocketListening = false
        print("🧹 ChatList Socket 리스너 정리 완료")
    }

    // MARK: - Chat Room Loading

    private func loadChatRooms() {
        state.isLoading = true
        state.errorMessage = nil

        Task {
            do {
                let response = try await networkService.request(
                    ChatRouter.fetchRoomList,
                    responseType: ChatRoomListDTO.self
                )

                let chatRooms = convertToChatRooms(response.data)

                await MainActor.run {
                    state.chatRooms = chatRooms
                    state.isLoading = false
                    print("✅ 전체 \(response.data.count)개 중 \(state.filteredChatRooms.count)개 채팅방 로드 완료 (나와의 채팅 제외)")
                }

            } catch {
                await MainActor.run {
                    state.errorMessage = "채팅방을 불러오는데 실패했습니다: \(error.localizedDescription)"
                    state.isLoading = false
                    state.chatRooms = []
                    print("⚠️ 채팅방 로드 실패: \(error)")
                }
            }
        }
    }

    private func refreshChatRooms() {
        guard !state.isRefreshing else { return }

        state.isRefreshing = true

        Task {
            do {
                let response = try await networkService.request(
                    ChatRouter.fetchRoomList,
                    responseType: ChatRoomListDTO.self
                )

                let chatRooms = convertToChatRooms(response.data)

                await MainActor.run {
                    state.chatRooms = chatRooms
                    state.isRefreshing = false
                    print("🔄 새로고침 완료: 전체 \(response.data.count)개 중 \(state.filteredChatRooms.count)개 (나와의 채팅 제외)")
                }

            } catch {
                await MainActor.run {
                    state.isRefreshing = false
                    print("❌ 채팅방 새로고침 실패: \(error)")
                    // 새로고침 실패시 기존 데이터 유지
                }
            }
        }
    }

    private func retryLoadChatRooms() {
        state.errorMessage = nil
        loadChatRooms()
    }

    // MARK: - Room Selection

    private func selectChatRoom(_ room: ChatRoom) {
        state.selectedRoom = room

        // 다른 채팅방으로 이동 시 Socket.IO 방 전환
        socketManager.openWebSocket(roomId: room.id)
        print("🔌 선택된 채팅방으로 Socket 연결: \(room.id)")
    }

    // MARK: - Helper Methods

    private func convertToChatRooms(_ dtos: [ChatRoomDTO]) -> [ChatRoom] {
        return dtos.map { dto in
            let participants = dto.participants.map { userDTO in
                User(
                    userId: userDTO.userId,
                    nickname: userDTO.nick,
                    profileImageURL: userDTO.profileImage
                )
            }

            var lastChat: ChatMessage? = nil
            if let lastChatDTO = dto.lastChat {
                let sender = User(
                    userId: lastChatDTO.sender.userId,
                    nickname: lastChatDTO.sender.nick,
                    profileImageURL: lastChatDTO.sender.profileImage
                )
                lastChat = ChatMessage(
                    id: lastChatDTO.chatId,
                    roomId: lastChatDTO.roomId,
                    content: lastChatDTO.content,
                    createdAt: ISO8601DateFormatter().date(from: lastChatDTO.createdAt) ?? Date(),
                    sender: sender,
                    files: lastChatDTO.files
                )
            }

            var chatRoom = ChatRoom(
                id: dto.roomId,
                participants: participants,
                lastChat: lastChat,
                createdAt: ISO8601DateFormatter().date(from: dto.createdAt) ?? Date(),
                updatedAt: ISO8601DateFormatter().date(from: dto.updatedAt) ?? Date()
            )

            // Realm에서 읽지 않은 메시지 개수 계산
            let lastReadMessageId = ChatRealmService.shared.getLastReadMessageId(roomId: dto.roomId)
            chatRoom.unreadCount = ChatRealmService.shared.getUnreadCount(roomId: dto.roomId, lastReadMessageId: lastReadMessageId)

            return chatRoom
        }
    }
}
