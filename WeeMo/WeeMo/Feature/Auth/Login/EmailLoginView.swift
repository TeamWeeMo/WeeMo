//
//  EmailLoginView.swift
//  WeeMo
//
//  Created by Lee on 11/19/25.
//

import SwiftUI

struct EmailLoginView: View {
    @StateObject private var loginStore = LoginStore()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.wmBg
                .ignoresSafeArea()

            VStack(spacing: 12) {
                // 타이틀
                VStack(spacing: 6) {
                    VStack {
                        Text("이메일 로그인")
                            .font(.app(.headline3))

                        Rectangle()
                            .frame(width: 20, height: 2)
                            .foregroundStyle(.wmMain)
                    }
                }

                VStack(alignment: .leading, spacing: 16) {
                    // 아이디
                    VStack(alignment: .leading, spacing: 4) {
                        Text("아이디")
                            .font(.app(.content2))
                            .foregroundStyle(.textMain)

                        TextField("아이디를 입력하세요", text: Binding(
                            get: { loginStore.state.id },
                            set: { loginStore.send(.idChanged($0)) }
                        ))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .asMintCornerView()

                        if !loginStore.state.idError.isEmpty {
                            Text(loginStore.state.idError)
                                .font(.app(.subContent2))
                                .foregroundStyle(.red)
                        }
                    }

                    // 비밀번호
                    VStack(alignment: .leading, spacing: 4) {
                        Text("비밀번호")
                            .font(.app(.content2))
                            .foregroundStyle(.textMain)

                        SecureField("비밀번호를 입력하세요", text: Binding(
                            get: { loginStore.state.pw },
                            set: { loginStore.send(.pwChanged($0)) }
                        ))
                        .asMintCornerView()

                        if !loginStore.state.pwError.isEmpty {
                            Text(loginStore.state.pwError)
                                .font(.app(.subContent2))
                                .foregroundStyle(.red)
                        }
                    }

                    // 로그인 버튼
                    Button {
                        loginStore.send(.loginTapped)
                    } label: {
                        if loginStore.state.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .frame(maxWidth: .infinity, minHeight: 46)
                        } else {
                            Text("로그인")
                                .font(.app(.subHeadline2))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 46)
                        }
                    }
                    .background(.wmMain)
                    .cornerRadius(8)
                    .disabled(loginStore.state.isLoading)

                    // 에러 메시지
                    if let errorMessage = loginStore.state.loginErrorMessage {
                        Text(errorMessage)
                            .font(.app(.subContent2))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .onChange(of: loginStore.state.isLoginSucceeded) { oldValue, newValue in
            if newValue {
                print("[EmailLoginView] 로그인 성공 - AppState 업데이트")
                appState.login()
                dismiss()
            }
        }
    }
}

#Preview {
    EmailLoginView()
}
