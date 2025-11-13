//
//  AuthRouter.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/13/25.
//

import Foundation
import Alamofire

// MARK: - Auth Router

enum AuthRouter: APIRouter {
    case emailValidation(email: String)
    case join(email: String, password: String, nickname: String)
    case login(email: String, password: String)
    case loginKakao(oauthToken: String)
    case loginApple(idToken: String, nickname: String?)
    case refreshToken(refreshToken: String)
    case withdraw

    // MARK: - APIRouter Implementation

    var method: HTTPMethod {
        switch self {
        case .emailValidation, .join, .login, .loginKakao, .loginApple:
            return .post
        case .refreshToken, .withdraw:
            return .get
        }
    }

    var path: String {
        let version = NetworkConstants.apiVersion
        switch self {
        case .emailValidation:
            return "\(version)/users/validation/email"
        case .join:
            return "\(version)/users/join"
        case .login:
            return "\(version)/users/login"
        case .loginKakao:
            return "\(version)/users/login/kakao"
        case .loginApple:
            return "\(version)/users/login/apple"
        case .refreshToken:
            return "\(version)/auth/refresh"
        case .withdraw:
            return "\(version)/users/withdraw"
        }
    }

    var parameters: Parameters? {
        switch self {
        case .emailValidation(let email):
            return ["email": email]

        case .join(let email, let password, let nickname):
            return [
                "email": email,
                "password": password,
                "nick": nickname
            ]

        case .login(let email, let password):
            return [
                "email": email,
                "password": password
            ]

        case .loginKakao(let oauthToken):
            return ["oauthToken": oauthToken]

        case .loginApple(let idToken, let nickname):
            var params: Parameters = ["idToken": idToken]
            if let nickname = nickname {
                params["nick"] = nickname
            }
            return params

        case .refreshToken, .withdraw:
            return nil
        }
    }

    var needsAuthorization: Bool {
        switch self {
        case .emailValidation, .join, .login, .loginKakao, .loginApple:
            return false
        case .refreshToken, .withdraw:
            return true
        }
    }

    var additionalHeaders: HTTPHeaders? {
        switch self {
        case .refreshToken(let refreshToken):
            return HTTPHeaders([HTTPHeader(name: HTTPHeaderKey.refresh, value: refreshToken)])
        default:
            return nil
        }
    }
}
