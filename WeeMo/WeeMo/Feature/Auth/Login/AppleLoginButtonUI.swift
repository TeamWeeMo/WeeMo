//
//  AppleLoginButtonUI.swift
//  WeeMo
//
//  Created by Lee on 11/8/25.
//

import SwiftUI
import AuthenticationServices

struct AppleLoginButtonUI: View {
    @State private var authorizationHelper = AppleAuthorizationHelper()
    var onLogin: (String) -> Void

    var body: some View {
        Button {
            authorizationHelper.onLoginSuccess = onLogin
            authorizationHelper.startAppleLogin()
        } label: {
            Circle()
                .fill(.black)
                .frame(width: 70, height: 70)
                .overlay {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 30))
                        .foregroundStyle(.white)
                }
        }
    }
}

// MARK: - Apple Authorization Helper
class AppleAuthorizationHelper: NSObject, ASAuthorizationControllerDelegate {
    var onLoginSuccess: ((String) -> Void)?

    func startAppleLogin() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }

    // MARK: - ASAuthorizationControllerDelegate
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            print("애플 로그인 실패: identityToken을 가져올 수 없습니다")
            return
        }

        // 이메일 정보 로깅
        print("======== Apple Credential 정보 ========")
        print("email: \(appleIDCredential.email ?? "nil")")
        print("user: \(appleIDCredential.user)")
        print("fullName: \(appleIDCredential.fullName?.givenName ?? "nil") \(appleIDCredential.fullName?.familyName ?? "nil")")

        DispatchQueue.main.async {
            self.onLoginSuccess?(identityToken)
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("애플 로그인 실패: \(error.localizedDescription)")
    }
}

#Preview {
    AppleLoginButtonUI { idToken in
        print("idToken: \(idToken)")
    }
}
