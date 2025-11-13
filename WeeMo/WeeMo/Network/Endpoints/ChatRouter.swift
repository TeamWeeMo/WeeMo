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
    case uploadChatFiles(roomId: String, files: [Data])

    // MARK: - APIRouter Implementation

    var method: HTTPMethod {
        switch self {
        case .createOrFetchRoom, .uploadChatFiles:
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
            return ["cursor_date": cursorDate]

        case .uploadChatFiles:
            return nil
        }
    }
}
