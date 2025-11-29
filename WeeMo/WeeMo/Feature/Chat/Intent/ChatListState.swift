//
//  ChatListState.swift
//  WeeMo
//
//  Created by 차지용 on 11/24/25.
//

import Foundation

struct ChatListState {
    var chatRooms: [ChatRoom] = []
    var selectedRoom: ChatRoom? = nil
    var isLoading: Bool = false
    var isRefreshing: Bool = false
    var errorMessage: String? = nil
    var isSocketListening: Bool = false

    // Computed properties
    var isEmpty: Bool {
        return chatRooms.isEmpty && !isLoading
    }

    var currentUserId: String {
        return TokenManager.shared.userId ?? ""
    }

    var filteredChatRooms: [ChatRoom] {
        return chatRooms.filter { room in
            // 1. 메시지가 있는 채팅방만 포함 (lastChat이 있어야 함)
            guard room.lastChat != nil else {
                return false
            }

            // 2. 참여자가 2명이고, 상대방이 나 자신이 아닌 경우만 포함
            if room.participants.count == 2 {
                return room.participants.contains { $0.userId != currentUserId }
            }
            return true // 그룹채팅은 일단 모두 포함
        }
    }
}
