//
//  APIRouter.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/13/25.
//

import Foundation
import Alamofire

// MARK: - API Router Protocol

/// 모든 API Router가 준수해야 하는 프로토콜
protocol APIRouter: URLRequestConvertible {
    /// HTTP Method
    var method: HTTPMethod { get }

    /// API Path (baseURL 이후 경로)
    var path: String { get }

    /// Request Parameters
    var parameters: Parameters? { get }

    /// Parameter Encoding
    var encoding: ParameterEncoding { get }

    /// 추가 헤더 (기본 헤더 외)
    var additionalHeaders: HTTPHeaders? { get }

    /// 인증 필요 여부
    var needsAuthorization: Bool { get }
}

// MARK: - Default Implementation

extension APIRouter {
    /// Base URL
    var baseURL: String {
        NetworkConstants.baseURL
    }

    /// 기본 헤더
    var defaultHeaders: HTTPHeaders {
        var headers = HTTPHeaders()

        // SeSACKey (항상 필수)
        if let sesacKey = Bundle.main.object(forInfoDictionaryKey: "SeSACKey") as? String {
            headers.add(name: HTTPHeaderKey.sesacKey, value: sesacKey)
        } else {
            print("❌ APIRouter - SeSACKey를 찾을 수 없음")
        }

        // ProductId (항상 필수)
        headers.add(name: HTTPHeaderKey.productId, value: NetworkConstants.productId)

        // Content-Type
        headers.add(name: HTTPHeaderKey.contentType, value: "application/json")

        return headers
    }

    /// Authorization 헤더 추가
    var authorizationHeader: HTTPHeaders? {
        guard needsAuthorization else { return nil }

        // TokenManager(Keychain)에서 AccessToken 가져오기
        guard let token = TokenManager.shared.accessToken else {
            return nil
        }

        return HTTPHeaders([HTTPHeader(name: HTTPHeaderKey.authorization, value: token)])
    }

    /// 최종 헤더
    var headers: HTTPHeaders {
        var finalHeaders = defaultHeaders

        // Authorization 헤더 추가
        if let authHeader = authorizationHeader {
            authHeader.forEach { finalHeaders.add($0) }
        }

        // 추가 헤더 병합
        if let additional = additionalHeaders {
            additional.forEach { finalHeaders.add($0) }
        }

        return finalHeaders
    }

    /// URLRequest 생성
    func asURLRequest() throws -> URLRequest {
        let url = try (baseURL + path).asURL()
        var request = URLRequest(url: url)
        request.method = method
        request.headers = headers
        request.timeoutInterval = 30

        return try encoding.encode(request, with: parameters)
    }
}

// MARK: - Default Values

extension APIRouter {
    var parameters: Parameters? { nil }
    var additionalHeaders: HTTPHeaders? { nil }
    var needsAuthorization: Bool { true }
    var encoding: ParameterEncoding {
        method == .get ? URLEncoding.default : JSONEncoding.default
    }
}
