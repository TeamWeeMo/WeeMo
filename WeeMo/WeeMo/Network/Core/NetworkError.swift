//
//  NetworkError.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/13/25.
//

import Foundation

// MARK: - Network Error

enum NetworkError: Error {
    // 데이터 에러
    case invalidResponse
    case noData
    case decodingFailed(Error)
    case encodingFailed(Error)

    // 인증 에러 (4xx)
    case invalidAccessToken         // 401 - 액세스 토큰 유효하지 않음
    case invalidRefreshToken        // 401 - 리프레시 토큰 유효하지 않음
    case forbidden                  // 403 - 접근 권한 없음
    case refreshTokenExpired        // 418 - 리프레시 토큰 만료
    case accessTokenExpired         // 419 - 액세스 토큰 만료
    case invalidSeSACKey            // 420 - SeSACKey 유효하지 않음
    case invalidProductId           // 421 - ProductId 유효하지 않음

    // 클라이언트 에러 (4xx)
    case badRequest(String)         // 400 - 필수값 누락, 잘못된 요청
    case invalidInput(String)       // 402 - 유효하지 않은 입력 (공백 포함 등)
    case notFound(String)           // 404 - 리소스 없음
    case conflict(String)           // 409 - 중복 등
    case tooManyRequests            // 429 - 과호출
    case abnormalRequest            // 444 - 비정상 API 호출
    case permissionDenied(String)   // 445 - 권한 없음 (삭제, 채팅 참여 등)

    // 서버 에러 (5xx)
    case serverError(String)        // 500 - 서버 에러

    // 기타
    case unknown(Error)

    // MARK: - User-Friendly Message

    var localizedDescription: String {
        switch self {
        // 데이터 에러
        case .invalidResponse:
            return "서버 응답이 유효하지 않습니다."
        case .noData:
            return "데이터가 없습니다."
        case .decodingFailed(let error):
            return "데이터 처리 중 오류가 발생했습니다."
        case .encodingFailed(let error):
            return "요청 데이터 생성 중 오류가 발생했습니다."

        // 인증 에러
        case .invalidAccessToken:
            return "인증할 수 없는 액세스 토큰입니다."
        case .invalidRefreshToken:
            return "인증할 수 없는 리프레시 토큰입니다."
        case .forbidden:
            return "접근 권한이 없습니다."
        case .refreshTokenExpired:
            return "리프레시 토큰이 만료되었습니다. 다시 로그인 해주세요."
        case .accessTokenExpired:
            return "액세스 토큰이 만료되었습니다."
        case .invalidSeSACKey:
            return "서비스 키가 유효하지 않습니다."
        case .invalidProductId:
            return "서비스 식별자(ProductId)를 찾을 수 없습니다."

        // 클라이언트 에러
        case .badRequest(let message):
            return message
        case .invalidInput(let message):
            return message
        case .notFound(let message):
            return message
        case .conflict(let message):
            return message
        case .tooManyRequests:
            return "과호출입니다. 잠시 후 다시 시도해주세요."
        case .abnormalRequest:
            return "비정상적인 요청입니다."
        case .permissionDenied(let message):
            return message

        // 서버 에러
        case .serverError(let message):
            return message.isEmpty ? "서버 오류가 발생했습니다." : message

        // 기타
        case .unknown(let error):
            return "알 수 없는 오류가 발생했습니다."
        }
    }

    // MARK: - Should Retry

    /// 재시도 가능 여부
    var shouldRetry: Bool {
        switch self {
        case .accessTokenExpired, .tooManyRequests:
            return true
        default:
            return false
        }
    }

    // MARK: - Should Force Logout

    /// 강제 로그아웃 필요 여부
    var shouldForceLogout: Bool {
        switch self {
        case .invalidRefreshToken, .refreshTokenExpired:
            return true
        default:
            return false
        }
    }
}
