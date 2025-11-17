//
//  LoginStroe.swift
//  WeeMo
//
//  Created by Lee on 11/14/25.
//

import Foundation
import Combine
import KakaoSDKUser
import KakaoSDKAuth

@MainActor
final class LoginStore: ObservableObject {

    @Published private(set) var state = LoginState()

    private let authService: AuthServicing

    init(authService: AuthServicing = AuthService()) {
        self.authService = authService
    }

    func send(_ intent: LoginIntent) {
        switch intent {
        case .idChanged(let newId):
            state.id = newId
            state.idError = AuthValidator.checkId(newId)

        case .pwChanged(let newPw):
            state.pw = newPw
            state.pwError = AuthValidator.checkPw(newPw)

        case .loginTapped:
            loginTapped()

        case .kakaoLoginTapped:
            kakaoLoginTapped()
        }
    }

    private func loginTapped() {
        print("loginTapped 호출, id = \(state.id), pw = \(state.pw)")
        state.idError = AuthValidator.checkId(state.id)
        state.pwError = AuthValidator.checkPw(state.pw)

        print("idError: \(state.idError)")
        print("pwError: \(state.pwError)")

        guard state.idError.isEmpty, state.pwError.isEmpty else {
            print("검증 에러 나서 요청 안보냈음")
            return
        }

        state.isLoading = true
        state.loginErrorMessage = nil

        Task {
            print("Task 시작")
            do {
                let result = try await authService.login(
                    email: state.id,
                    password: state.pw
                )

                TokenManager.shared.saveTokens(
                    accessToken: result.accessToken,
                    refreshToken: result.refreshToken
                )

                print("\(result)")
                state.isLoading = false
                state.isLoginSucceeded = true
            } catch let error as NetworkError {
                print("error: \(error)")
                state.isLoading = false
                if error.shouldForceLogout {
                    print(error.localizedDescription)
                }

                switch error {
                case .invalidInput, .badRequest:
                    state.loginErrorMessage = "이메일 또는 비밀번호가 올바르지 않습니다"
                default:
                    state.loginErrorMessage = error.localizedDescription
                }
            } catch {
                print("error: \(error)")
                state.isLoading = false
                state.loginErrorMessage = "로그인에 실패했어요 다시 시도해주세요"
            }
        }
    }
}

extension LoginStore {
    private func kakaoLoginTapped() {
        state.isLoading = true
        state.loginErrorMessage = nil

        Task {
            do {
                let kakaoToken = try await loginWithKakao()
                print("카카오 토큰: \(String(kakaoToken.prefix(20)))")
                print("카카오 토큰 길이", kakaoToken.count)

                let result = try await authService.kakaoLogin(accessToken: kakaoToken)

                TokenManager.shared.saveTokens(
                    accessToken: result.accessToken,
                    refreshToken: result.refreshToken
                )

                state.isLoading = false
                state.isLoginSucceeded = true
            } catch let error as NetworkError {
                print("networkError", error)
                state.isLoading = false
                state.loginErrorMessage = error.localizedDescription
            } catch {
                print(error)
                state.isLoading = false
                state.loginErrorMessage = "카카오 로그인에 실패했어요"
            }
        }
    }

    private func loginWithKakao() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            if UserApi.isKakaoTalkLoginAvailable() {
                UserApi.shared.loginWithKakaoTalk { oauthToken, error in
                    if let error = error {
                        print(error)
                        continuation.resume(throwing: error)
                    } else if let token = oauthToken {
                        continuation.resume(returning: token.accessToken)
                    }
                }
            } else {
                UserApi.shared.loginWithKakaoAccount { oauthToken, error in
                    if let error = error {
                        print(error)
                        continuation.resume(throwing: error)
                    } else if let token = oauthToken {
                        continuation.resume(returning: token.accessToken)
                    }
                }
            }
        }
    }
}
