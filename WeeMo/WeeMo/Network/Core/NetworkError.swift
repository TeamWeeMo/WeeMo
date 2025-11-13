//
//  NetworkError.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/13/25.
//

import Foundation

// MARK: - Network Error
//TODO: - 수정 필요
enum NetworkError: Error {
    // HTTP 에러
    case invalidResponse
    case httpError(statusCode: Int, message: String?)

    // 데이터 에러
    case noData
    case decodingFailed(Error)
    case encodingFailed(Error)

    // 인증 에러
    case unauthorized           // 401
    case forbidden              // 403
    case tokenExpired           // Access Token 만료
    case refreshTokenExpired    // Refresh Token 만료

    // 기타
    case unknown(Error)
    case customError(String)

    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "유효하지 않은 응답입니다."
        case .httpError(let statusCode, let message):
            return "HTTP 에러 (\(statusCode)): \(message ?? "알 수 없는 에러")"
        case .noData:
            return "데이터가 없습니다."
        case .decodingFailed(let error):
            return "디코딩 실패: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "인코딩 실패: \(error.localizedDescription)"
        case .unauthorized:
            return "인증되지 않은 사용자입니다."
        case .forbidden:
            return "접근 권한이 없습니다."
        case .tokenExpired:
            return "토큰이 만료되었습니다."
        case .refreshTokenExpired:
            return "다시 로그인해주세요."
        case .unknown(let error):
            return "알 수 없는 에러: \(error.localizedDescription)"
        case .customError(let message):
            return message
        }
    }
}

// MARK: - Server Error Response

/// 서버 에러 응답 구조
struct ServerErrorResponse: Decodable {
    let message: String?
}
