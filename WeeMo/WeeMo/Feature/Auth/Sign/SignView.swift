//
//  SignView.swift
//  WeeMo
//
//  Created by Lee on 11/8/25.
//

import SwiftUI

struct SignView: View {
    @StateObject var signStore = SignStore()
    @EnvironmentObject var appState: AppState

    private var emailBinding: Binding<String> {
        Binding(
            get: { signStore.state.email },
            set: { signStore.send(.idChanged($0)) }
        )
    }

    private var passwordBinding: Binding<String> {
        Binding(
            get: { signStore.state.password },
            set: { signStore.send(.pwChanged($0)) }
        )
    }

    private var nicknameBinding: Binding<String> {
        Binding(
            get: { signStore.state.nickname },
            set: { signStore.send(.nicknameChanged($0)) }
        )
    }

    var body: some View {
        ZStack {
            Color.wmBg
                .ignoresSafeArea()

            VStack {
                VStack(spacing: 6) {
                    VStack {
                        Text("회원가입")
                            .font(.app(.headline3))

                        Rectangle()
                            .frame(width: 20, height: 2)
                            .foregroundStyle(.wmMain)
                    }
                }

                VStack(spacing: 10) {
                    // 이메일 입력
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("아이디")
                                .font(.app(.content1))
                            Spacer()
                            Button {
                                signStore.send(.emailValidTapped)
                            } label: {
                                Text("중복 확인")
                                    .font(.app(.subContent2))
                                    .foregroundStyle(.wmMain)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.wmMain, lineWidth: 1)
                                    )
                            }
                            .disabled(signStore.state.isLoading)
                        }

                        TextField("아이디를 입력하세요", text: emailBinding)
                            .asMintCornerView()

                        if signStore.state.isEmailValidated {
                            Text("사용 가능한 이메일입니다")
                                .font(.app(.subContent3))
                                .foregroundStyle(.green)
                        } else if !signStore.state.emailError.isEmpty {
                            Text(signStore.state.emailError)
                                .font(.app(.subContent3))
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // 비밀번호 입력
                    VStack(alignment: .leading, spacing: 4) {
                        Text("비밀번호")
                            .font(.app(.content1))
                        SecureField("비밀번호를 입력하세요", text: passwordBinding)
                            .asMintCornerView()
                        if !signStore.state.passwordError.isEmpty {
                            Text(signStore.state.passwordError)
                                .font(.app(.subContent3))
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal, 20)

                    // 닉네임 입력
                    VStack(alignment: .leading, spacing: 4) {
                        Text("닉네임")
                            .font(.app(.content1))
                        TextField("닉네임을 입력하세요", text: nicknameBinding)
                            .asMintCornerView()
                        if !signStore.state.nicknameError.isEmpty {
                            Text(signStore.state.nicknameError)
                                .font(.app(.subContent3))
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal, 20)

                    // 가입하기 버튼
                    Button {
                        signStore.send(.joinTapped)
                    } label: {
                        if signStore.state.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity, minHeight: 46)
                                .background(.wmMain)
                                .cornerRadius(12)
                        } else {
                            Text("가입하기")
                                .font(.app(.subHeadline2))
                                .frame(maxWidth: .infinity, minHeight: 46)
                                .foregroundStyle(.white)
                                .background(signStore.state.isEmailValidated ? .wmMain : .gray)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(!signStore.state.isEmailValidated || signStore.state.isLoading)
                    .padding(20)

                    // 에러 메시지
                    if let errorMessage = signStore.state.signUpErrorMessage {
                        Text(errorMessage)
                            .font(.app(.subContent2))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 20)
                    }
                }
                .background(.white)
                .cornerRadius(12)
                .padding(20)
                .shadow(radius: 3)
            }
        }
        .navigationTitle("")
        .navigationDestination(isPresented: Binding(
            get: { signStore.state.isSignUpSucceeded },
            set: { _ in }
        )) {
            ProfileEditView(isNewProfile: true)
        }
        .onChange(of: signStore.state.isSignUpSucceeded) { oldValue, newValue in
            if newValue {
                print("✅ [SignView] 회원가입 성공 - AppState 업데이트")
                appState.login()
            }
        }
    }
}


#Preview {
    SignView()
}
