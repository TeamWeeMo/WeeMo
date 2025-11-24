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

    let userId: String?  // nil이면 내 프로필, 값이 있으면 다른 사람 프로필

    @StateObject private var profileStore: ProfileStore
    @EnvironmentObject var appState: AppState
    @Namespace private var underlineNS
    @State private var shouldNavigateToEdit = false

    // 내 프로필인지 확인
    private var isMyProfile: Bool {
        guard let userId = userId else { return true }
        return userId == TokenManager.shared.userId
    }

    init(userId: String? = nil) {
        self.userId = userId
        _profileStore = StateObject(wrappedValue: ProfileStore(userId: userId))
    }

    var body: some View {
        ScrollView {
                VStack(spacing: 0) {
                    // 프로필 헤더 섹션 (프로필 이미지 + 닉네임 + 통계 바)
                    ZStack(alignment: .topLeading) {
                        // 닉네임 + 통계 바 (먼저 배치 - 뒤쪽)
                        VStack(spacing: 0) {
                            // 닉네임 영역
                            HStack {
                                Spacer()
                                    .frame(width: 144)  // 프로필 이미지 공간 + 여백

                                VStack(alignment: .leading, spacing: 4) {
                                    if isMyProfile {
                                        Text("반가워요,")
                                            .font(.app(.headline3))
                                            .foregroundStyle(.textMain)

                                        HStack(alignment: .center) {
                                            Text((UserManager.shared.nickname ?? "닉네임") + "님")
                                                .font(.app(.headline2))
                                                .foregroundStyle(.textMain)

                                            Spacer()

                                            // 설정 버튼 (내 프로필일 때만)
                                            Button {
                                                shouldNavigateToEdit = true
                                            } label: {
                                                Image(systemName: "gearshape")
                                                    .font(.system(size: 20))
                                                    .foregroundStyle(.textMain)
                                            }
                                        }
                                    } else {
                                        let nickname = profileStore.state.otherUserProfile?.nick ?? "닉네임"
                                        HStack {
                                            Text("\(nickname)의 프로필")
                                                .font(.app(.headline3))
                                                .foregroundStyle(.textMain)

                                            Spacer()

                                            // 채팅 버튼 (다른 사람 프로필일 때만)
                                            Button {
                                                print("채팅 버튼 클릭 - userId: \(userId ?? "nil")")
                                                // TODO: 채팅 화면으로 이동
                                            } label: {
                                                Image(systemName: "message")
                                                    .font(.system(size: 20))
                                                    .foregroundStyle(.textMain)
                                            }
                                        }
                                    }
                                }

                                Spacer()
                                    .frame(width: 20)
                            }
                            .padding(.top, 40)
                            .frame(height: 100)  // 닉네임 영역 고정 높이

                            // 민트색 통계 바 (원형 하단과 정렬)
                            HStack(spacing: 0) {
                                // 프로필 이미지와 겹치지 않도록 여백
                                Spacer()
                                    .frame(width: 40)

                                VStack(spacing: 4) {
                                    Text("팔로잉")
                                        .font(.app(.subContent3))
                                        .foregroundStyle(.white)
                                    if isMyProfile {
                                        Text(profileStore.state.following, format: .number)
                                            .font(.app(.content2))
                                            .foregroundStyle(.white)
                                    } else {
                                        Text(profileStore.state.otherUserProfile?.following.count ?? 0, format: .number)
                                            .font(.app(.content2))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)

                                VStack(spacing: 4) {
                                    Text("팔로워")
                                        .font(.app(.subContent3))
                                        .foregroundStyle(.white)
                                    if isMyProfile {
                                        Text(profileStore.state.follower, format: .number)
                                            .font(.app(.content2))
                                            .foregroundStyle(.white)
                                    } else {
                                        Text(profileStore.state.otherUserProfile?.followers.count ?? 0, format: .number)
                                            .font(.app(.content2))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)

                                VStack(spacing: 4) {
                                    Text("게시글")
                                        .font(.app(.subContent3))
                                        .foregroundStyle(.white)
                                    Text("\(profileStore.state.userMeetings.count + profileStore.state.userFeeds.count)")
                                        .font(.app(.content2))
                                        .foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.vertical, 16)
                            .frame(height: 60)  // 통계 바 고정 높이
                            .background(.wmMain)
                            .padding(.leading, 80)  // 원형 중심점에서 시작 (20 + 60)
                        }

                        // 프로필 이미지 (나중에 배치 - 앞쪽)
                        VStack {
                            let profileImageURL = isMyProfile
                            ? UserManager.shared.profileImageURL
                            : profileStore.state.otherUserProfile?.profileImage

                            if let profileImageURL = profileImageURL,
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
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(.wmMain, lineWidth: 2)
                                    )
                            } else {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60, height: 60)
                                            .foregroundStyle(.gray)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(.wmMain, lineWidth: 2)
                                    )
                            }
                        }
                        .padding(.leading, 20)
                        .padding(.top, 40)
                    }
                    .frame(height: 160)  // 전체 높이를 원형 이미지 높이와 맞춤 (40 + 120)

                    // 내 프로필일 때만 탭 표시
                    if isMyProfile {
                        UnderlineSegmented(
                            selection: Binding(
                                get: { profileStore.state.selectedTab },
                                set: { profileStore.send(.tabChanged($0)) }
                            ),
                            underlineNS: underlineNS
                        )
                        .padding(.horizontal, Spacing.medium)
                        .padding(.top, 16)
                        .padding(.bottom, 5)
                    } else {
                        // 다른 사람 프로필일 때는 "게시글" 텍스트만 표시
                        HStack {
                            Text("게시글")
                                .font(.app(.headline3))
                                .foregroundStyle(.wmMain)
                            Spacer()
                        }
                        .padding(.horizontal, Spacing.base)
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                    }

                    // 내 프로필: 탭에 따라 다른 컨텐츠, 다른 사람 프로필: 항상 게시글만
                    if isMyProfile {
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
                                            .frame(height: 276)
                                    } else if profileStore.state.userMeetings.isEmpty {
                                        Text("작성한 모임이 없습니다")
                                            .font(.app(.subContent2))
                                            .foregroundStyle(.textSub)
                                            .frame(height: 276)
                                            .frame(maxWidth: .infinity)
                                    } else {
                                        LargeMeetingSection(items: profileStore.state.userMeetings.map { post in
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
                    } else {
                        // 다른 사람 프로필: 항상 게시글만 표시
                        VStack(alignment: .leading, spacing: 8) {
                            // 작성한 모임 섹션
                            VStack(alignment: .leading, spacing: 8) {
                                Text("작성한 모임 (\(profileStore.state.userMeetings.count))")
                                    .font(.app(.content2))
                                    .foregroundStyle(.textMain)
                                    .padding(.horizontal, 16)

                                if profileStore.state.isLoadingMeetings {
                                    ProgressView()
                                        .frame(height: 276)
                                } else if profileStore.state.userMeetings.isEmpty {
                                    Text("작성한 모임이 없습니다")
                                        .font(.app(.subContent2))
                                        .foregroundStyle(.textSub)
                                        .frame(height: 276)
                                        .frame(maxWidth: .infinity)
                                } else {
                                    LargeMeetingSection(items: profileStore.state.userMeetings.map { post in
                                        let imageURL = post.files.first.map { FileRouter.fileURL(from: $0) }
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
                                    TwoRowHorizontalSection(items: profileStore.state.userFeeds.map { post in
                                        let imageURL = post.files.first.map { FileRouter.fileURL(from: $0) }
                                        return (title: post.title, imageURL: imageURL)
                                    })
                                }
                            }
                        }
                        .padding(.top, 12)
                    }

                    // 내 프로필일 때만 로그아웃/회원탈퇴 표시
                    if isMyProfile {
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
                }
                .padding(.top, 12)
            }
            .background(.wmBg)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // task는 화면이 나타날 때 한 번만 실행됨 (onAppear보다 효율적)
                print("[ProfileView] task 호출됨")

                // 이미 데이터가 있으면 스킵 (빠른 화면 전환)
                if profileStore.state.userMeetings.isEmpty && profileStore.state.userFeeds.isEmpty {
                    profileStore.send(.loadInitialData)
                }
            }
            .onChange(of: profileStore.state.selectedTab) { _, newTab in
                // 내 프로필일 때만 탭 변경 처리
                guard isMyProfile else { return }

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
            .navigationDestination(isPresented: $shouldNavigateToEdit) {
                ProfileEditView(isNewProfile: false)
            }
    }
}


#Preview {
    ProfileView()
}
