//
//  LoginView.swift
//  WeeMo
//
//  Created by Lee on 11/8/25.
//

import SwiftUI

enum AuthRoute: Hashable {
    case emailLogin
    case signup
    case profileEdit
}

struct LoginView: View {

    @StateObject var loginStore = LoginStore()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.wmBg
                    .ignoresSafeArea()

                VStack(spacing: 0) {
//                    // 상단 X 버튼
//                    HStack {
//                        Spacer()
//                        Button {
//                            dismiss()
//                        } label: {
//                            Image(systemName: "xmark")
//                                .font(.system(size: 20))
//                                .foregroundStyle(.textMain)
//                        }
//                        .padding()
//                    }

                    Spacer()

                    // 로고 + WeeMo 텍스트
                    HStack(spacing: 4) {
                        Image("WeeMoLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)

                        Text("WeeMo")
                            .font(.app(.headline1))
                            .foregroundStyle(.textMain)
                    }
                    .padding(.bottom, 30)

                    // 타이틀
                    HStack(spacing: 0) {
                        Text("우리만의 ")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.textMain)
                        Text("프라이빗 모임!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.wmMain)
                    }
                    .padding(.bottom, 60)

                    Spacer()

                    // 소셜 로그인 버튼들
                    VStack(spacing: 20) {
                        HStack(spacing: 30) {
                            // 카카오 로그인
                            Button {
                                loginStore.send(.kakaoLoginTapped)
                            } label: {
                                Circle()
                                    .fill(Color("kakaoBg"))
                                    .frame(width: 70, height: 70)
                                    .overlay {
                                        Image(systemName: "message.fill")
                                            .font(.system(size: 30))
                                            .foregroundStyle(Color("kakaoSymbol"))
                                    }
                            }

                            // 이메일 로그인
                            NavigationLink(value: AuthRoute.emailLogin) {
                                Circle()
                                    .fill(.wmMain)
                                    .frame(width: 70, height: 70)
                                    .overlay {
                                        Image(systemName: "envelope.fill")
                                            .font(.system(size: 30))
                                            .foregroundStyle(.white)
                                    }
                            }

                            // 애플 로그인
                            AppleLoginButtonUI { idToken in
                                loginStore.send(.appleLoginTapped(idToken: idToken))
                            }
                        }

                        NavigationLink(value: AuthRoute.signup) {
                            Text("이메일로 가입하기")
                                .font(.app(.content2))
                                .foregroundStyle(.textMain)
                                .padding(.top, 10)
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle("")
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .emailLogin: EmailLoginView()
                case .signup: SignView()
                case .profileEdit: ProfileEditView(isNewProfile: true)
                }
            }
        }
        .tint(.wmMain)
        .onChange(of: loginStore.state.isLoginSucceeded) { oldValue, newValue in
            if newValue {
                print("[LoginView] 로그인 성공 - AppState 업데이트")
                appState.login()
            }
        }
    }
}

#Preview {
    LoginView()
}
