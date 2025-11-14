//
//  LoginStroe.swift
//  WeeMo
//
//  Created by Lee on 11/14/25.
//

import Foundation
import Combine

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
            state.idError = LoginValidator.checkId(newId)

        case .pwChanged(let newPw):
            state.pw = newPw
            state.pwError = LoginValidator.checkPw(newPw)

        case .loginTapped:
            loginTapped()
        }
    }

    private func loginTapped() {
        print("loginTapped 호출, id = \(state.id), pw = \(state.pw)")
        state.idError = LoginValidator.checkId(state.id)
        state.pwError = LoginValidator.checkPw(state.pw)

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
                let dto = try await authService.login(
                    email: state.id,
                    password: state.pw
                )

                print("\(dto)")
                state.isLoading = false
                state.isLoginSucceeded = true
            } catch let error as NetworkError {
                print("error: \(error)")
                state.isLoading = false
                state.loginErrorMessage = mapNetworkError(error)
            } catch {
                print("error: \(error)")
                state.isLoading = false
                state.loginErrorMessage = "로그인에 실패했어요 다시 시도해주세요"
            }
        }
    }

    private func mapNetworkError(_ error: NetworkError) -> String {
        switch error {
        case .unauthorized:
            return "이메일 또는 비밀번호가 올바르지 않아요"
        case .forbidden:
            return "접근 권한이 없어요"
        case .tokenExpired:
            return "세션 만료입니다. 다시 로그인해주세요"
        case .httpError(_, let message):
            return message ?? "요청에 실패했어요"
        case .unknown:
            return "네트워크 오류가 발생했어요. 잠시 후 다시 시도해주세요"
        default:
            return ""
        }
    }
}

enum LoginValidator {
    static func checkId(_ id: String) -> String {
        if id.isEmpty {
            return "이메일을 입력해주세요"
        } else if !id.contains("@") {
            return "이메일 형식이 잘못되었어요"
        } else if id.count >= 100 {
            return "이메일이 너무 길어요. 다시 확인해주세요"
        } else {
            return ""
        }
    }

    static func checkPw(_ pw: String) -> String {
        let pattern = "^(?!.*[.,?*\\-@+\\^${\\}()|\\[\\]\\\\])\\S+$"

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return "비밀번호 형식을 확인해주세요"
        }

        let range = NSRange(location: 0, length: pw.utf16.count)
        let isMatch = regex.firstMatch(in: pw, range: range) != nil

        if pw.isEmpty {
            return "비밀번호를 입력해주세요"
        }

        if !isMatch {
            return "공백 또는 특수문자는 사용할 수 없어요"
        } else {
            return ""
        }
    }
}
