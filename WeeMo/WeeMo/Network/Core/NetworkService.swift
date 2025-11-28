//
//  NetworkService.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/13/25.
//

import Foundation
import Alamofire
import Combine

// MARK: - Network Service Implementation

/// 네트워크 요청을 처리하는 서비스 (기본 구현)
final class NetworkService: NetworkServiceProtocol {
    // MARK: - Properties

    private let session: Session

    // MARK: - Initializer

    init(session: Session? = nil) {
        if let session = session {
            self.session = session
        } else {
            let interceptor = AuthInterceptor()
            self.session = Session(interceptor: interceptor)
        }
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

    /// 미디어 파일 업로드 (이미지/영상 구분)
    func uploadMedia<T: Decodable>(
        _ router: APIRouter,
        mediaFiles: [Data],
        responseType: T.Type
    ) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            session.upload(
                multipartFormData: { multipartFormData in
                    for (index, mediaData) in mediaFiles.enumerated() {
                        let (fileName, mimeType) = self.detectMediaType(data: mediaData, index: index)
                        multipartFormData.append(
                            mediaData,
                            withName: "files",
                            fileName: fileName,
                            mimeType: mimeType
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

    /// 미디어 데이터 타입 감지
    private func detectMediaType(data: Data, index: Int) -> (fileName: String, mimeType: String) {
        guard data.count > 12 else {
            return ("file_\(index)", "application/octet-stream")
        }

        let bytes = data.prefix(12)
        let signature = bytes.map { String(format: "%02x", $0) }.joined()
        let sig = signature.lowercased()

        // 이미지 포맷
        if sig.hasPrefix("ffd8ff") {
            return ("image_\(index).jpg", "image/jpeg")
        }
        if sig.hasPrefix("89504e47") {
            return ("image_\(index).png", "image/png")
        }
        if sig.hasPrefix("47494638") {
            return ("image_\(index).gif", "image/gif")
        }
        if sig.hasPrefix("52494646") {
            return ("image_\(index).webp", "image/webp")
        }

        // 영상 파일은 MP4로 처리
        return ("video_\(index).mp4", "video/mp4")
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

        // NetworkErrorMapper를 통해 상태 코드와 서버 메시지를 NetworkError로 변환
        return NetworkErrorMapper.map(
            statusCode: statusCode,
            data: data,
            afError: error
        )
    }

    // MARK: - Combine Support

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
