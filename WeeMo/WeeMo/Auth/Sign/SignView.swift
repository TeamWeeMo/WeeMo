//
//  SignView.swift
//  WeeMo
//
//  Created by Lee on 11/8/25.
//

import SwiftUI

struct SignView: View {
    @State private var id: String = ""

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
                    VStack(alignment: .leading) {
                        Text("아이디")
                            .font(.app(.content1))
                        TextField("아이디를 입력하세요", text: $id)
                            .asMintCornerView()
                        Text("이메일 형식이 잘못되었어요")
                            .font(.app(.subContent3))
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    VStack(alignment: .leading) {
                        Text("비밀번호")
                            .font(.app(.content1))
                        TextField("비밀번호를 입력하세요", text: $id)
                            .asMintCornerView()
                        Text("비밀번호 형식이 잘못되었어요")
                            .font(.app(.subContent3))
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 20)

                    VStack(alignment: .leading) {
                        Text("닉네임")
                            .font(.app(.content1))
                        TextField("닉네임을 입력하세요", text: $id)
                            .asMintCornerView()
                        Text("닉네임 형식이 잘못되었어요")
                            .font(.app(.subContent3))
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 20)

                    NavigationLink(value: AuthRoute.profileEdit) {
                        Text("가입하기")
                            .font(.app(.subHeadline2))
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .foregroundStyle(.white)
                            .background(.wmMain)
                            .cornerRadius(12)
                    }
                    .padding(20)
                }
                .background(.white)
                .cornerRadius(12)
                .padding(20)
                .shadow(radius: 3)
            }
        }
        .navigationTitle("")
    }
}


#Preview {
    SignView()
}
