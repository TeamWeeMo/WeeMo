//
//  LoginView.swift
//  WeeMo
//
//  Created by Lee on 11/8/25.
//

import SwiftUI

enum AuthRoute: Hashable {
    case signup
    case profileEdit
}

struct LoginView: View {

    @StateObject var loginStore = LoginStore()
    @EnvironmentObject var appState: AppState

    private var idBinding: Binding<String> {
        Binding(
            get: { loginStore.state.id },
            set: { loginStore.send(.idChanged($0))}
        )
    }

    private var pwBinding: Binding<String> {
        Binding(
            get: { loginStore.state.pw },
            set: { loginStore.send(.pwChanged($0)) }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.wmBg
                    .ignoresSafeArea()

                VStack(spacing: 10) {
                    VStack(spacing: 6) {
                        /// 폰트, 컬러 사용 예시
                        Text("WeeMo")
                            .font(.app(.headline1))
                            .foregroundStyle(.wmMain)
                        Text("모두를 위한 모임, 위모")
                            .font(.app(.content2))
                            .foregroundStyle(.textSub)
                    }

                    VStack(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("아이디")
                                    .font(.app(.content2))
                                TextField("아이디를 입력하세요", text: idBinding)
                                    .asMintCornerView()
                                Text(loginStore.state.idError)
                                    .font(.app(.subContent2))
                                    .foregroundStyle(.red)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("비밀번호")
                                    .font(.app(.content2))
                                SecureField("비밀번호를 입력하세요", text: pwBinding)
                                    .asMintCornerView()
                                Text(loginStore.state.pwError)
                                    .font(.app(.subContent2))
                                    .foregroundStyle(.red)
                            }

                            Button {
                                loginStore.send(.loginTapped)
                            } label: {
                                Text("로그인")
                                    .font(.app(.subHeadline2))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity,
                                           minHeight: 46,
                                           alignment: .center)
                                    .background(.wmMain)
                                    .cornerRadius(8)
                            }
                            

                            ZStack {
                                Rectangle()
                                    .frame(height: 1)
                                    .background(.textSub)

                                Text("또는")
                                    .padding(10)
                                    .foregroundStyle(.textSub)
                                    .background(.white)
                            }

                            Button {
                                print("버튼 클릭")
                            } label: {
                                Image("kakao_login_large_wide")
                                    .resizable()
                                    .frame(maxWidth: .infinity, maxHeight: 46)
                            }

                            Button {
                                print("버튼 클릭")
                            } label: {
                                AppleLoginButtonUI()
                            }

                            NavigationLink(value: AuthRoute.signup) {
                                Text("이메일로 회원가입")
                                    .font(.app(.content2))
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .navigationTitle("")
                        .tint(.blue)
                        .padding(30)

                    }
                    .background(.white)
                    .cornerRadius(16)
                    .padding(20)
                    .shadow(radius: 3)
                }
            }
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
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
