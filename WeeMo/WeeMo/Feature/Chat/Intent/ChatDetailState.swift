//
//  ChatDetailState.swift
//  WeeMo
//
//  Created by 차지용 on 11/24/25.
//

import Foundation
import PhotosUI

struct ChatDetailState {
    var room: ChatRoom
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var isSendingMessage: Bool = false
    var errorMessage: String? = nil
    var isSocketConnected: Bool = false
    var shouldScrollToBottom: Bool = false
    var hasMoreMessages: Bool = true
    var showPlusMenu: Bool = false
    var selectedImages: [Data] = []
    var showImageGallery: Bool = false
    var galleryImages: [String] = []
    var galleryStartIndex: Int = 0

    init(room: ChatRoom) {
        self.room = room
    }
}

// MARK: - Computed Properties
extension ChatDetailState {
    var currentUserId: String {
        return TokenManager.shared.userId ?? ""
    }

    var canSendMessage: Bool {
        return !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSendingMessage
    }
}
