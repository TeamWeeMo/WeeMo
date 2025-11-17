//
//  AuthInterceptor.swift
//  WeeMo
//
//  Created by Lee on 11/14/25.
//

import Foundation
import Alamofire

final class AuthInterceptor: RequestInterceptor {
    // AuthService를 사용하지 않고 직접 Session 생성
    private let refreshSession: Session

    init() {
        // refreshToken 요청용 별도 Session (인터셉터 없이)
        self.refreshSession = Session()
    }

    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        completion(.success(urlRequest))
    }

    func retry(_ request: Request,
               for session: Session,
               dueTo error: any Error,
               completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse else {
            completion(.doNotRetryWithError(error))
            return
        }

        guard response.statusCode == 419 else {
            completion(.doNotRetryWithError(error))
            return
        }

        print("[AuthInterceptor] 419 에러 감지 - 토큰 갱신 시작")

        Task {
            do {
                print("[AuthInterceptor] refreshAccessToken 호출 중...")

                // refreshToken 가져오기
                guard let refreshToken = TokenManager.shared.refreshToken else {
                    throw NetworkError.refreshTokenExpired
                }

                // 직접 API 호출 (순환 참조 방지)
                let newTokens = try await refreshSession.request(
                    AuthRouter.refreshToken(refreshToken: refreshToken)
                )
                .validate()
                .serializingDecodable(RefreshTokenDTO.self)
                .value

                print("[AuthInterceptor] 토큰 갱신 성공!")
                print("  - 새 accessToken: \(String(newTokens.accessToken.prefix(20)))...")

                TokenManager.shared.saveTokens(
                    accessToken: newTokens.accessToken,
                    refreshToken: newTokens.refreshToken
                )

                print("[AuthInterceptor] 새 토큰 Keychain에 저장 완료")
                print("[AuthInterceptor] 원래 요청 재시도")

                completion(.retry)
            } catch {
                print("[AuthInterceptor] 토큰 갱신 실패: \(error)")
                print("[AuthInterceptor] 토큰 삭제 및 로그아웃 처리")

                TokenManager.shared.clearTokens()
                completion(.doNotRetryWithError(NetworkError.refreshTokenExpired))
            }
        }
    }
}
