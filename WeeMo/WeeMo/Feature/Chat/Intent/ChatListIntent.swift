//
//  ChatListIntent.swift
//  WeeMo
//
//  Created by 차지용 on 11/24/25.
//

import Foundation

enum ChatListIntent {
    case loadChatRooms
    case refreshChatRooms
    case retryLoadChatRooms
    case selectChatRoom(ChatRoom)
    case setupSocketListeners
    case cleanupSocketListeners
}
