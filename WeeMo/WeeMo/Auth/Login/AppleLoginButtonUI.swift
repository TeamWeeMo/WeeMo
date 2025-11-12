//
//  AppleLoginButtonUI.swift
//  WeeMo
//
//  Created by Lee on 11/8/25.
//

import SwiftUI
import AuthenticationServices

struct AppleLoginButtonUI: View {
    var style: SignInWithAppleButton.Style = .black
    var height: CGFloat = 46
    var cornerRadius: CGFloat = 8
    var body: some View {
        SignInWithAppleButton(.signIn) { _ in
            // 요청 구성
        } onCompletion: { _ in
            // 결과 처리
        }
        .signInWithAppleButtonStyle(style)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

#Preview {
    AppleLoginButtonUI()
}
