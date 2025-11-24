//
//  ChatDetailIntent.swift
//  WeeMo
//
//  Created by 차지용 on 11/24/25.
//

import Foundation

enum ChatDetailIntent {
    case loadMessages(roomId: String)
    case sendMessage(content: String, files: [String]? = nil)
    case setupSocketConnection(roomId: String)
    case closeSocketConnection
    case loadMoreMessages(beforeMessageId: String)
    case retryLoadMessages
    case markAsRead
}
