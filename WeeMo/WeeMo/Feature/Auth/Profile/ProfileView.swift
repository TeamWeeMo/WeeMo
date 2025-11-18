//
//  ProfileView.swift
//  WeeMo
//
//  Created by Lee on 11/10/25.
//

import SwiftUI
import Kingfisher

enum Route: Hashable {
    case edit
}

struct ProfileView: View {

    @StateObject private var profileStore = ProfileStore()
    @EnvironmentObject var appState: AppState
    @Namespace private var underlineNS

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.small) {
                    Group {
                        if let profileImageURL = UserManager.shared.profileImageURL,
                           let url = URL(string: FileRouter.fileURL(from: profileImageURL)) {
                            KFImage(url)
                                .withAuthHeaders()
                                .placeholder {
                                    Circle()
                                        .fill(.white)
                                        .overlay {
                                            ProgressView()
                                        }
                                }
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .padding(5)
                                .overlay(
                                    Circle()
                                        .stroke(.wmMain, lineWidth: 1)
                                )
                        } else {
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .padding(5)
                                .asCircleRoundView()
                        }
                    }
                    .padding(.top, 40)
                    
                    Text(UserManager.shared.nickname ?? "닉네임")
                        .font(.app(.subHeadline1))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    HStack(spacing: 40) {
                        VStack {
                            Text(profileStore.state.following, format: .number)
                                .font(.app(.subHeadline1))
                            Text("팔로잉")
                                .font(.app(.subContent2))
                        }
                        VStack {
                            Text(profileStore.state.follower, format: .number)
                                .font(.app(.subHeadline1))
                            Text("팔로워")
                                .font(.app(.subContent2))
                        }

                        VStack {
                            Text(profileStore.state.manner, format: .number.precision(.fractionLength(0...1)))
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
                    
                    UnderlineSegmented(
                        selection: Binding(
                            get: { profileStore.state.selectedTab },
                            set: { profileStore.send(.tabChanged($0)) }
                        ),
                        underlineNS: underlineNS
                    )
                    .padding(.horizontal, Spacing.medium)
                    .padding(.bottom, 5)

                    switch profileStore.state.selectedTab {
                    case .posts:
                        VStack(alignment: .leading, spacing: 8) {
                            // 작성한 모임 섹션
                            VStack(alignment: .leading, spacing: 8) {
                                Text("작성한 모임 (\(profileStore.state.userMeetings.count))")
                                    .font(.app(.content2))
                                    .foregroundStyle(.textMain)
                                    .padding(.horizontal, 16)

                                if profileStore.state.isLoadingMeetings {
                                    ProgressView()
                                        .frame(height: 116)
                                } else if profileStore.state.userMeetings.isEmpty {
                                    Text("작성한 모임이 없습니다")
                                        .font(.app(.subContent2))
                                        .foregroundStyle(.textSub)
                                        .frame(height: 116)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    HorizontalScrollSection(items: profileStore.state.userMeetings.map { post in
                                        let imageURL = post.files.first.map { FileRouter.fileURL(from: $0) }
                                        print("[ProfileView] 작성한 모임 이미지 URL: \(imageURL ?? "nil")")
                                        return (title: post.title, imageURL: imageURL)
                                    })
                                }
                            }

                            // 작성한 피드 섹션
                            VStack(alignment: .leading, spacing: 8) {
                                Text("작성한 피드 (\(profileStore.state.userFeeds.count))")
                                    .font(.app(.content2))
                                    .foregroundStyle(.textMain)
                                    .padding(.horizontal, 16)

                                if profileStore.state.isLoadingFeeds {
                                    ProgressView()
                                        .frame(height: 216)
                                } else if profileStore.state.userFeeds.isEmpty {
                                    Text("작성한 피드가 없습니다")
                                        .font(.app(.subContent2))
                                        .foregroundStyle(.textSub)
                                        .frame(height: 216)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    let _ = print("[ProfileView] 피드 렌더링 - count: \(profileStore.state.userFeeds.count), titles: \(profileStore.state.userFeeds.map { $0.title })")
                                    TwoRowHorizontalSection(items: profileStore.state.userFeeds.map { post in
                                        let imageURL = post.files.first.map { FileRouter.fileURL(from: $0) }
                                        print("[ProfileView] 피드 이미지 URL: \(imageURL ?? "nil"), files: \(post.files)")
                                        return (title: post.title, imageURL: imageURL)
                                    })
                                }
                            }
                        }
                        .padding(.top, 12)
                    case .groups:
                        if profileStore.state.isLoadingLikedPosts {
                            ProgressView()
                                .frame(height: 400)
                        } else if profileStore.state.likedPosts.isEmpty {
                            Text("찜한 모임이 없습니다")
                                .font(.app(.subContent2))
                                .foregroundStyle(.textSub)
                                .frame(height: 400)
                                .frame(maxWidth: .infinity)
                        } else {
                            ProfileGridSection(columnCount: 3, items: profileStore.state.likedPosts.map { post in
                                let imageURL = post.files.first.map { FileRouter.fileURL(from: $0) }
                                return (title: post.title, imageURL: imageURL)
                            })
                        }
                    case .likes:
                        if profileStore.state.isLoadingPaidPosts {
                            ProgressView()
                                .frame(height: 400)
                        } else if profileStore.state.paidPosts.isEmpty {
                            Text("결제한 모임이 없습니다")
                                .font(.app(.subContent2))
                                .foregroundStyle(.textSub)
                                .frame(height: 400)
                                .frame(maxWidth: .infinity)
                        } else {
                            ProfileGridSection(columnCount: 3, items: profileStore.state.paidPosts.map { payment in
                                // TODO: PaymentHistoryDTO에서 이미지 정보를 가져올 방법이 필요할 수 있음
                                return (title: payment.productName, imageURL: nil)
                            })
                        }
                    }

                    Rectangle()
                        .frame(width: 20, height: 2)
                        .foregroundStyle(.wmMain)

                    Button {
                        appState.logout()
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
            .onAppear {
                print("[ProfileView] onAppear 호출됨")
                profileStore.send(.loadInitialData)
            }
        }
        .tint(.wmMain)
        .onChange(of: profileStore.state.selectedTab) { _, newTab in
            // 탭 변경 시 해당 탭의 데이터 로드
            switch newTab {
            case .posts:
                // 이미 초기 로드에서 불러왔으므로 스킵
                break
            case .groups:
                if profileStore.state.likedPosts.isEmpty && !profileStore.state.isLoadingLikedPosts {
                    profileStore.send(.loadLikedPosts)
                }
            case .likes:
                if profileStore.state.paidPosts.isEmpty && !profileStore.state.isLoadingPaidPosts {
                    profileStore.send(.loadPaidPosts)
                }
            }
        }
    }
}


#Preview {
    ProfileView()
}
