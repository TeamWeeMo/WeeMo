//
//  UserRouter.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/13/25.
//

import Foundation
import Alamofire

// MARK: - User Router

enum UserRouter: APIRouter {
    // 프로필
    case updateMyProfile(nickname: String?, profileImage: Data?)
    case fetchMyProfile
    case fetchUserProfile(userId: String)

    // 검색
    case searchUser(nickname: String)

    // 팔로우
    case toggleFollow(userId: String)

    // MARK: - APIRouter Implementation

    var method: HTTPMethod {
        switch self {
        case .updateMyProfile:
            return .put
        case .fetchMyProfile, .fetchUserProfile, .searchUser:
            return .get
        case .toggleFollow:
            return .post
        }
    }

    var path: String {
        let version = NetworkConstants.apiVersion
        switch self {
        case .updateMyProfile, .fetchMyProfile:
            return "\(version)/users/me/profile"
        case .fetchUserProfile(let userId):
            return "\(version)/users/\(userId)/profile"
        case .searchUser:
            return "\(version)/users/search"
        case .toggleFollow(let userId):
            return "\(version)/follow/\(userId)"
        }
    }

    var parameters: Parameters? {
        switch self {
        case .updateMyProfile(let nickname, _):
            // 프로필 이미지는 multipart로 전송되므로 여기서는 nickname만
            guard let nickname = nickname else { return nil }
            return ["nick": nickname]

        case .fetchMyProfile, .fetchUserProfile:
            return nil

        case .searchUser(let nickname):
            return ["nick": nickname]

        case .toggleFollow:
            return nil
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .updateMyProfile:
            // Multipart는 NetworkService에서 처리
            return JSONEncoding.default
        default:
            return method == .get ? URLEncoding.default : JSONEncoding.default
        }
    }
}
