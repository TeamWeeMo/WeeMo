//
//  NetworkErrorMapper.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation
import Alamofire

// MARK: - Network Error Mapper

/// HTTP 응답을 NetworkError로 매핑
struct NetworkErrorMapper {

    /// HTTP 응답 → NetworkError 변환
    static func map(
        statusCode: Int,
        data: Data?,
        afError: AFError
    ) -> NetworkError {
        // 서버 메시지 파싱
        let serverMessage = parseServerMessage(from: data)

        switch statusCode {
        // 400번대 - 클라이언트 에러
        case 400:
            return .badRequest(serverMessage ?? "필수값을 채워주세요.")

        case 401:
            // 메시지로 구분 (AccessToken vs RefreshToken vs 로그인 실패)
            if serverMessage?.contains("리프레시") == true {
                return .invalidRefreshToken
            } else if let message = serverMessage, !message.isEmpty {
                // 서버 메시지가 있으면 badRequest로 처리 (로그인 실패 등)
                return .badRequest(message)
            } else {
                return .invalidAccessToken
            }

        case 402:
            return .invalidInput(serverMessage ?? "유효하지 않은 입력입니다.")

        case 403:
            return .forbidden

        case 404:
            return .notFound(serverMessage ?? "요청한 리소스를 찾을 수 없습니다.")

        case 445:
            return .permissionDenied(serverMessage ?? "권한이 없습니다.")

        case 409:
            return .conflict(serverMessage ?? "중복된 요청입니다.")

        case 418:
            return .refreshTokenExpired

        case 419:
            return .accessTokenExpired

        case 420:
            return .invalidSeSACKey

        case 421:
            return .invalidProductId

        case 429:
            return .tooManyRequests

        case 444:
            return .abnormalRequest

        // 500번대 - 서버 에러
        case 500..<600:
            return .serverError(serverMessage ?? "")

        // 기타
        default:
            return .unknown(afError)
        }
    }

    // MARK: - Private Helpers

    /// Data에서 서버 에러 메시지 파싱
    private static func parseServerMessage(from data: Data?) -> String? {
        guard let data else { return nil }

        do {
            let response = try JSONDecoder().decode(ServerResponseDTO.self, from: data)
            return response.message
        } catch {
            return nil
        }
    }
}
