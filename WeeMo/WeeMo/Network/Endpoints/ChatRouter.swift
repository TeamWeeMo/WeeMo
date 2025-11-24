//
//  ChatRouter.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/13/25.
//

import Foundation
import Alamofire

// MARK: - Chat Router

enum ChatRouter: APIRouter {
    case createOrFetchRoom(opponentUserId: String)
    case fetchRoomList
    case fetchMessages(roomId: String, cursorDate: String?)
    case sendMessage(roomId: String, content: String, files: [String]?)
    case uploadChatFiles(roomId: String, files: [Data])

    // MARK: - APIRouter Implementation

    var method: HTTPMethod {
        switch self {
        case .createOrFetchRoom, .sendMessage, .uploadChatFiles:
            return .post
        case .fetchRoomList, .fetchMessages:
            return .get
        }
    }

    var path: String {
        let version = NetworkConstants.apiVersion
        switch self {
        case .createOrFetchRoom:
            return "\(version)/chats"
        case .fetchRoomList:
            return "\(version)/chats"
        case .fetchMessages(let roomId, _):
            return "\(version)/chats/\(roomId)"
        case .sendMessage(let roomId, _, _):
            return "\(version)/chats/\(roomId)"
        case .uploadChatFiles(let roomId, _):
            return "\(version)/chats/\(roomId)/files"
        }
    }

    var parameters: Parameters? {
        switch self {
        case .createOrFetchRoom(let opponentUserId):
            return ["opponent_id": opponentUserId]

        case .fetchRoomList:
            return nil

        case .fetchMessages(_, let cursorDate):
            guard let cursorDate = cursorDate else { return nil }
            // 일반적인 페이징 파라미터명 사용
            return ["before": cursorDate]

        case .sendMessage(_, let content, let files):
            var params: [String: Any] = ["content": content]
            if let files = files {
                params["files"] = files
            }
            return params

        case .uploadChatFiles:
            return nil
        }
    }
}
