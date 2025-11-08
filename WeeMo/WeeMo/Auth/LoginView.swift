//
//  LoginView.swift
//  WeeMo
//
//  Created by Lee on 11/8/25.
//

import SwiftUI

struct LoginView: View {
    @State private var id = ""
    var body: some View {
        ZStack {
            Color.wmBg
                .ignoresSafeArea()

            VStack(spacing: 10) {
                VStack(spacing: 6) {
                    /// 폰트, 컬러 사용 예시
                    Text("WeeMo")
                        .font(.app(.headline1))
                        .foregroundStyle(.wmMain)
                    Text("공간을 예약하고 모임을 만들어 보세요")
                        .font(.app(.content2))
                        .foregroundStyle(.textSub)
                }

                VStack(alignment: .leading) {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("아이디")
                                .font(.app(.content1))
                            TextField("아이디를 입력하세요", text: $id)
                                .frame(height: 12)
                                .asGrayBackgroundView()
                            Text("이메일 형식이 잘못되었어요")
                                .font(.app(.subContent3))
                                .foregroundStyle(.red)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("비밀번호")
                                .font(.app(.content1))
                            TextField("비밀번호를 입력하세요", text: $id)
                                .frame(height: 12)
                                .asGrayBackgroundView()
                            Text("비밀번호 형식이 잘못되었어요")
                                .font(.app(.subContent3))
                                .foregroundStyle(.red)
                        }

                        Button {
                            print("버튼 클릭")
                        } label: {
                            Text("로그인")
                                .font(.app(.subHeadline2))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity,
                                       maxHeight: 46,
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
                                .frame(width: .infinity, height: 46)
                        }

                        Button {
                            print("버튼 클릭")
                        } label: {
                            Text("Apple 로그인")
                                .bold()
                                .foregroundStyle(.white)
                                .padding(20)
                                .frame(maxWidth: .infinity,
                                       maxHeight: 46,
                                       alignment: .center)
                                .background(.black)
                                .cornerRadius(8)
                        }

                        Button {
                            print("버튼 클릭")
                        } label: {
                            Text("이메일로 회원가입")
                                .font(.app(.content2))
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(30)

                }
                .background(.white)
                .cornerRadius(16)
                .padding(20)
                .shadow(radius: 3)
            }
        }
    }
}

#Preview {
    LoginView()
}
