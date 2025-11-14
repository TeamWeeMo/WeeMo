//
//  NetworkServiceProtocol.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/14/25.
//

import Foundation
import Combine

// MARK: - Network Service Protocol

/// 네트워크 요청을 처리하는 서비스 프로토콜
protocol NetworkServiceProtocol {
    /// 기본 요청 (Decodable 응답)
    func request<T: Decodable>(
        _ router: APIRouter,
        responseType: T.Type
    ) async throws -> T

    /// Void 응답 (응답 바디 없음)
    func request(_ router: APIRouter) async throws

    /// 파일 업로드 (Multipart)
    func upload<T: Decodable>(
        _ router: APIRouter,
        images: [Data],
        responseType: T.Type
    ) async throws -> T

    /// 파일 다운로드
    func downloadFile(_ router: APIRouter) async throws -> Data

    /// Combine Publisher 방식 요청
    func requestPublisher<T: Decodable>(
        _ router: APIRouter,
        responseType: T.Type
    ) -> AnyPublisher<T, NetworkError>
}
