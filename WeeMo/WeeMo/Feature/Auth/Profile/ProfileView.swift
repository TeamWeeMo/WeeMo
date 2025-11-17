//
//  ProfileView.swift
//  WeeMo
//
//  Created by Lee on 11/10/25.
//

import SwiftUI

enum Route: Hashable {
    case edit
}

struct ProfileView: View {

    @Namespace private var underlineNS
    @State private var selection: ProfileTab = .posts

    @State private var following = 23
    @State private var follower = 45
    @State private var manner: Double = 4.8

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.small) {
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .padding(5)
                        .asCircleRoundView()
                        .padding(.top, 40)
                    
                    Text("닉네임")
                        .font(.app(.subHeadline1))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    HStack(spacing: 40) {
                        VStack {
                            Text(following, format: .number)
                                .font(.app(.subHeadline1))
                            Text("팔로잉")
                                .font(.app(.subContent2))
                        }
                        VStack {
                            Text(follower, format: .number)
                                .font(.app(.subHeadline1))
                            Text("팔로워")
                                .font(.app(.subContent2))
                        }
                        
                        VStack {
                            Text(manner, format: .number.precision(.fractionLength(0...1)))
                                .font(.app(.subHeadline1))
                            Text("모임매너")
                                .font(.app(.subContent2))
                        }
                    }
                    
                    HStack(spacing: Spacing.medium) {
                        NavigationLink(value: Route.edit) {
                            Text("편집")
                                .font(.app(.content2))
                                .foregroundStyle(.textMain)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .asMintCornerView()
                        }
                        
                        Button {
                            print("버튼을 눌렀습니다")
                        } label: {
                            Text("공유")
                                .foregroundStyle(.textMain)
                        }
                        .asMintCornerView()
                        .frame(maxWidth: .infinity)
                    }
                    .padding(Spacing.base)
                    
                    UnderlineSegmented(selection: $selection, underlineNS: underlineNS)
                        .padding(.horizontal, Spacing.medium)
                        .padding(.bottom, 5)

                    switch selection {
                    case .posts:
                        VStack(alignment: .leading, spacing: 8) {
                            // 작성한 모임 섹션
                            VStack(alignment: .leading, spacing: 8) {
                                Text("작성한 모임 (10)")
                                    .font(.app(.content2))
                                    .foregroundStyle(.textMain)
                                    .padding(.horizontal, 16)

                                HorizontalScrollSection(items: (1...10).map { "작성한 모임 \($0)" })
                            }

                            // 작성한 피드 섹션
                            VStack(alignment: .leading, spacing: 8) {
                                Text("작성한 피드 (14)")
                                    .font(.app(.content2))
                                    .foregroundStyle(.textMain)
                                    .padding(.horizontal, 16)

                                TwoRowHorizontalSection(items: (1...14).map { "작성한 피드 \($0)" })
                            }
                        }
                        .padding(.top, 12)
                    case .groups:
                        ProfileGridSection(columnCount: 3, items: (1...20).map { "찜한 모임 \($0)" })
                    case .likes:
                        ProfileGridSection(columnCount: 3, items: (1...20).map { "결제한 모임 \($0)" })
                    }

                    Rectangle()
                        .frame(width: 20, height: 2)
                        .foregroundStyle(.wmMain)

                    Button {
                        print("로그아웃")
                    } label: {
                        Text("로그아웃")
                            .foregroundStyle(.textMain)
                    }
                    .asMintCornerView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                    .padding(.horizontal, 20)
                    
                    Button {
                        print("회원탈퇴")
                    } label: {
                        Text("회원탈퇴")
                            .foregroundStyle(.textMain)
                    }
                    .asMintCornerView()
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 12)
            }
            .background(.wmBg)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .edit: ProfileEditView(isNewProfile: false)
                }
            }
            .navigationTitle("")
        }
        .tint(.wmMain)
    }
}


#Preview {
    ProfileView()
}
