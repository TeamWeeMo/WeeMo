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
                    for (index, fileData) in images.enumerated() {
                        let fileInfo = self.detectFileType(from: fileData)

                        multipartFormData.append(
                            fileData,
                            withName: "files",
                            fileName: "file_\(index)\(fileInfo.extension)",
                            mimeType: fileInfo.mimeType
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

    // MARK: - Helper(파일 타입 감지)
    private func detectFileType(from data: Data) -> (extension: String, mimeType: String) {
        guard data.count >= 12 else {
            return ("jpg", "image/jpeg")
        }

        let bytes = [UInt8](data.prefix(12))

        // MP4 체크
        if bytes.count >= 12,
           bytes[4] == 0x66, bytes[5] == 0x74, bytes[6] == 0x79, bytes[7] == 0x70 {
            // "ftyp" signature (MP4/MOV)
            return (".mp4", "video/mp4")
        }

        // JPEG 체크
        if bytes.count >= 2,
           bytes[0] == 0xFF, bytes[1] == 0xD8 {
            return (".jpg", "image/jpeg")
        }

        // PNG 체크
        if bytes.count >= 8,
           bytes[0] == 0x89, bytes[1] == 0x50, bytes[2] == 0x4E, bytes[3] == 0x47 {
            return (".png", "image/png")
        }

        // 기본값 (JPEG)
        return (".jpg", "image/jpeg")
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
