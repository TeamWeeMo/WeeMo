//
//  NetworkService.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/13/25.
//

import Foundation
import Alamofire
import Combine

/// MVI MVVM
/// aysnc await

// MARK: - Network Service

/// 네트워크 요청을 처리하는 서비스
final class NetworkService {
    // MARK: - Properties

    private let session: Session

    // MARK: - Initializer

    init(session: Session = .default) {
        self.session = session
    }

    // MARK: - Request Methods

    /// 기본 요청 (Decodable 응답)
    func request<T: Decodable>(
        _ router: APIRouter,
        responseType: T.Type
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            session.request(router)
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let data):
                        continuation.resume(returning: data)

                    case .failure(let error):
                        let networkError = self.handleError(response: response.response, error: error, data: response.data)
                        continuation.resume(throwing: networkError)
                    }
                }
        }
    }

    /// Void 응답 (응답 바디 없음)
    func request(_ router: APIRouter) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            session.request(router)
                .validate()
                .response { response in
                    if let error = response.error {
                        let networkError = self.handleError(response: response.response, error: error, data: response.data)
                        continuation.resume(throwing: networkError)
                    } else {
                        continuation.resume()
                    }
                }
        }
    }

    /// 파일 업로드 (Multipart)
    func upload<T: Decodable>(
        _ router: APIRouter,
        images: [Data],
        responseType: T.Type
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            session.upload(
                multipartFormData: { multipartFormData in
                    for (index, imageData) in images.enumerated() {
                        multipartFormData.append(
                            imageData,
                            withName: "files",
                            fileName: "image_\(index).jpg",
                            mimeType: "image/jpeg"
                        )
                    }
                },
                with: router
            )
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let data):
                    continuation.resume(returning: data)

                case .failure(let error):
                    let networkError = self.handleError(response: response.response, error: error, data: response.data)
                    continuation.resume(throwing: networkError)
                }
            }
        }
    }

    /// 파일 다운로드 (이미지, 비디오 등)
    func downloadFile(_ router: APIRouter) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            session.request(router)
                .validate()
                .responseData { response in
                    switch response.result {
                    case .success(let data):
                        continuation.resume(returning: data)

                    case .failure(let error):
                        let networkError = self.handleError(response: response.response, error: error, data: response.data)
                        continuation.resume(throwing: networkError)
                    }
                }
        }
    }

    // MARK: - Error Handling

    private func handleError(
        response: HTTPURLResponse?,
        error: AFError,
        data: Data?
    ) -> NetworkError {
        guard let statusCode = response?.statusCode else {
            return .unknown(error)
        }

        // 서버 에러 메시지 파싱 시도
        var serverMessage: String?
        if let data = data {
            serverMessage = try? JSONDecoder().decode(ServerErrorResponse.self, from: data).message
        }

        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 419:
            return .tokenExpired
        case 400..<500:
            return .httpError(statusCode: statusCode, message: serverMessage)
        case 500..<600:
            return .httpError(statusCode: statusCode, message: serverMessage ?? "서버 에러가 발생했습니다.")
        default:
            return .unknown(error)
        }
    }
}

// MARK: - Combine Support (Optional)

extension NetworkService {
    /// Combine Publisher 방식 요청
    func requestPublisher<T: Decodable>(
        _ router: APIRouter,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        return session.request(router)
            .validate()
            .publishDecodable(type: T.self)
            .value()
            .mapError { error in
                return .unknown(error)
            }
            .eraseToAnyPublisher()
    }
}
