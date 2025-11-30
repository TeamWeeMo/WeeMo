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
import AuthenticationServices

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

        case .appleLoginTapped(let idToken):
            appleLoginTapped(idToken: idToken)
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
                TokenManager.shared.saveUserId(result.userId)
                UserManager.shared.saveNickname(result.nick)
                UserManager.shared.saveProfileImageURL(result.profileImage)

                print("\(result)")
                print("[LoginStore] userId 저장 완료: \(result.userId)")
                print("[LoginStore] nickname 저장 완료: \(result.nick)")
                print("[LoginStore] profileImageURL 저장 완료: \(result.profileImage ?? "nil")")
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
                TokenManager.shared.saveUserId(result.userId)
                UserManager.shared.saveNickname(result.nick)
                UserManager.shared.saveProfileImageURL(result.profileImage)

                print("[LoginStore] userId 저장 완료: \(result.userId)")
                print("[LoginStore] nickname 저장 완료: \(result.nick)")
                print("[LoginStore] profileImageURL 저장 완료: \(result.profileImage ?? "nil")")
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

    private func appleLoginTapped(idToken: String) {
        state.isLoading = true
        state.loginErrorMessage = nil

        Task {
            do {
                print("애플 idToken: \(String(idToken))")
                print("애플 idToken 전체 길이: \(idToken.count)")

                let result = try await authService.appleLogin(idToken: idToken)

                TokenManager.shared.saveTokens(
                    accessToken: result.accessToken,
                    refreshToken: result.refreshToken
                )
                TokenManager.shared.saveUserId(result.userId)
                UserManager.shared.saveNickname(result.nick)
                UserManager.shared.saveProfileImageURL(result.profileImage)

                print("[LoginStore] 애플 로그인 성공!")
                print("[LoginStore] userId 저장 완료: \(result.userId)")
                print("[LoginStore] nickname 저장 완료: \(result.nick)")
                print("[LoginStore] profileImageURL 저장 완료: \(result.profileImage ?? "nil")")
                state.isLoading = false
                state.isLoginSucceeded = true
            } catch let error as NetworkError {
                print("======== 애플 로그인 실패 ========")
                print("NetworkError 타입: \(error)")
                print("에러 메시지: \(error.localizedDescription)")

                switch error {
                case .serverError(let message):
                    print("서버 에러 상세: \(message)")
                case .badRequest(let message):
                    print("잘못된 요청: \(message)")
                case .invalidInput(let message):
                    print("유효하지 않은 입력: \(message)")
                default:
                    print("기타 에러")
                }

                state.isLoading = false
                state.loginErrorMessage = error.localizedDescription
            } catch {
                print("======== 애플 로그인 알 수 없는 에러 ========")
                print("에러 타입: \(type(of: error))")
                print("에러 내용: \(error)")
                print("에러 localizedDescription: \(error.localizedDescription)")

                state.isLoading = false
                state.loginErrorMessage = "애플 로그인에 실패했어요"
            }
        }
    }
}
