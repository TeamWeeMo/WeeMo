//
//  CommentRouter.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/13/25.
//

import Foundation
import Alamofire

// MARK: - Comment Router

enum CommentRouter: APIRouter {
    case fetchComments(postId: String)
    case createComment(postId: String, content: String)
    case updateComment(postId: String, commentId: String, content: String)
    case deleteComment(postId: String, commentId: String)

    // MARK: - APIRouter Implementation

    var method: HTTPMethod {
        switch self {
        case .fetchComments:
            return .get
        case .createComment:
            return .post
        case .updateComment:
            return .put
        case .deleteComment:
            return .delete
        }
    }

    var path: String {
        let version = NetworkConstants.apiVersion
        switch self {
        case .fetchComments(let postId), .createComment(let postId, _):
            return "\(version)/posts/\(postId)/comments"
        case .updateComment(let postId, let commentId, _), .deleteComment(let postId, let commentId):
            return "\(version)/posts/\(postId)/comments/\(commentId)"
        }
    }

    var parameters: Parameters? {
        switch self {
        case .fetchComments:
            return nil
        case .createComment(_, let content):
            return ["content": content]
        case .updateComment(_, _, let content):
            return ["content": content]
        case .deleteComment:
            return nil
        }
    }
}
