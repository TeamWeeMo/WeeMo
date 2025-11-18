//
//  SignStore.swift
//  WeeMo
//
//  Created by Lee on 11/14/25.
//

import Foundation
import Combine

@MainActor
final class SignStore: ObservableObject {
    @Published private(set) var state = SignState()

    private let authService: AuthServicing

    init(authService: AuthServicing = AuthService()) {
        self.authService = authService
    }

    func send(_ intent: SignIntent) {
        switch intent {
        case .idChanged(let email):
            // 이메일이 실제로 변경된 경우에만 중복확인 상태 초기화
            if state.email != email {
                state.isEmailValidated = false
            }
            state.email = email
            state.emailError = ""

        case .pwChanged(let password):
            state.password = password
            state.passwordError = ""

        case .nicknameChanged(let nickname):
            state.nickname = nickname
            state.nicknameError = ""

        case .emailValidTapped:
            Task {
                await validateEmail()
            }

        case .joinTapped:
            Task {
                await signUp()
            }
        }
    }

    private func validateEmail() async {
        let errorMessage = AuthValidator.checkId(state.email)
        guard errorMessage.isEmpty else {
            state.emailError = errorMessage
            return
        }

        state.isLoading = true

        do {
            let response = try await authService.validateEmail(email: state.email)
            state.isEmailValidated = true
            state.emailError = ""
            print("이메일 검증 성공: \(response.message)")
        } catch let error as NetworkError {
            print("NetworkError 발생: \(error)")
            state.emailError = error.localizedDescription
            state.isEmailValidated = false
        } catch {
            print("알 수 없는 에러: \(error)")
            state.emailError = "네트워크 오류가 발생했습니다"
            state.isEmailValidated = false
        }

        state.isLoading = false
    }

    private func signUp() async {
        print("회원가입 시작")
        print("이메일: \(state.email)")
        print("비밀번호: \(state.password)")
        print("닉네임: \(state.nickname)")
        print("이메일 검증 완료: \(state.isEmailValidated)")

        guard validateAllFields() else {
            print("필드 검증 실패")
            print("  - 이메일 에러: \(state.emailError)")
            print("  - 비밀번호 에러: \(state.passwordError)")
            print("  - 닉네임 에러: \(state.nicknameError)")
            return
        }
        print("모든 필드 검증 통과")

        guard state.isEmailValidated else {
            print("이메일 중복 확인 필요")
            state.emailError = "이메일 중복 확인이 필요합니다"
            return
        }
        print("이메일 중복 확인 완료")

        state.isLoading = true
        print("API 호출 시작...")

        do {
            let result = try await authService.join(
                email: state.email,
                password: state.password,
                nickname: state.nickname
            )

            TokenManager.shared.saveTokens(
                accessToken: result.accessToken,
                refreshToken: result.refreshToken
            )

            print("회원가입 성공!")
            print("  - userId: \(result.userId)")
            print("  - email: \(result.email)")
            print("  - nickname: \(result.nick)")
            print("  - accessToken: \(result.accessToken)")

            state.isSignUpSucceeded = true
            state.signUpErrorMessage = nil

            print("State 업데이트 완료: isSignUpSucceeded = \(state.isSignUpSucceeded)")
        } catch let error as NetworkError {
            print("NetworkError 발생: \(error)")
            print("  - localizedDescription: \(error.localizedDescription)")
            state.signUpErrorMessage = error.localizedDescription
            state.isSignUpSucceeded = false
        } catch DecodingError.keyNotFound(let key, let context) {
            print("디코딩 에러 - 키 없음: \(key)")
            print("  - Context: \(context)")
            state.signUpErrorMessage = "서버 응답 형식이 올바르지 않습니다"
            state.isSignUpSucceeded = false
        } catch DecodingError.typeMismatch(let type, let context) {
            print("디코딩 에러 - 타입 불일치: \(type)")
            print("  - Context: \(context)")
            state.signUpErrorMessage = "서버 응답 형식이 올바르지 않습니다"
            state.isSignUpSucceeded = false
        } catch {
            print("알 수 없는 에러: \(error)")
            print("  - Type: \(type(of: error))")
            print("  - localizedDescription: \(error.localizedDescription)")
            state.signUpErrorMessage = error.localizedDescription
            state.isSignUpSucceeded = false
        }

        state.isLoading = false
    }

    private func validateAllFields() -> Bool {
        let emailError = AuthValidator.checkId(state.email)
        let pwError = AuthValidator.checkPw(state.password)
        let nicknameError = AuthValidator.checkNickname(state.nickname)

        state.emailError = emailError
        state.passwordError = pwError
        state.nicknameError = nicknameError

        return emailError.isEmpty && pwError.isEmpty && nicknameError.isEmpty
    }
}
