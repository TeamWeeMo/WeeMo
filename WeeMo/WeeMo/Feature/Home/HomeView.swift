//
//  HomeView.swift
//  WeeMo
//
//  Created by Lee on 11/20/25.
//

import SwiftUI

enum HomeRoute: Hashable {
    case meetList
    case meetEdit
    case spaceList
    case feed
    case profile
}

struct HomeView: View {

    @EnvironmentObject var appState: AppState
    @State private var navigationPath = NavigationPath()
    @State private var showLoginSheet = false
    @State private var pendingRoute: HomeRoute?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 0) {
                    // Top Navigation Bar
                    HStack {
                        Text("WeeMo")
                            .font(.app(.headline1))
                            .foregroundStyle(.wmMain)

                        Spacer()

                        // Chat Button
                        Button {
                            print("채팅 버튼 클릭")
                        } label: {
                            Image(systemName: "message")
                                .font(.system(size: 24))
                                .foregroundStyle(.textMain)
                        }
                        .padding(.trailing, 16)

                        // Profile Button
                        Button {
                            navigateWithLoginCheck(to: .profile)
                        } label: {
                            Image(systemName: "person.circle")
                                .font(.system(size: 24))
                                .foregroundStyle(.textMain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    // Main Feature Cards
                    VStack(spacing: 16) {
                        // 모임 찾기 (큰 카드)
                        LargeFeatureCard(
                            title: "모임 찾기",
                            description: "내 근처에 있는 모임 구경하기",
                            imageName: "person",
                            imageSize: CGSize(width: 88, height: 88)
                        ) {
                            navigateWithLoginCheck(to: .meetList)
                        }

                        HStack(spacing: 16) {
                            // 모임 등록하기 (작은 카드)
                            SmallFeatureCard(
                                title: "모임 등록하기",
                                description: "모임장 되어 시람 모으기",
                                imageName: "pencil",
                                imageSize: CGSize(width: 80, height: 80)
                            ) {
                                navigateWithLoginCheck(to: .meetEdit)
                            }

                            // 공간 찾기 (작은 카드)
                            SmallFeatureCard(
                                title: "공간 찾기",
                                description: "모이기 좋은 공간 찾기",
                                imageName: "find",
                                imageSize: CGSize(width: 70, height: 70)
                            ) {
                                navigateWithLoginCheck(to: .spaceList)
                            }
                        }

                        // 피드 (큰 카드)
                        LargeFeatureCard(
                            title: "피드",
                            description: "내 주변 시람, 관심사 확인하기",
                            imageName: "camera",
                            imageSize: CGSize(width: 88, height: 88)
                        ) {
                            navigateWithLoginCheck(to: .feed)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // 요즘 뜨는 모임
                    VStack(alignment: .leading, spacing: 12) {
                        Text("요즘 뜨는 모임")
                            .font(.app(.subHeadline1))
                            .foregroundStyle(.textMain)
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                TrendingMeetingCard(
                                    imageName: "promotionImage1",
                                    title: "대형 스크린과 함께\n즐기는 축구"
                                )

                                TrendingMeetingCard(
                                    imageName: "promotionImage2",
                                    title: "퇴근 후 와인과 함께\n소소한 대화"
                                )

                                TrendingMeetingCard(
                                    imageName: "promotionImage3",
                                    title: "독서와 함께 쌓는\n마음의 양식"
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 32)

                    Spacer(minLength: 40)
                }
            }
            .background(.wmBg)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .meetList:
                    MeetListView()
                case .meetEdit:
                    MeetEditView()
                case .spaceList:
                    SpaceListView()
                case .feed:
                    FeedView()
                case .profile:
                    ProfileView()
                }
            }
        }
        .sheet(isPresented: $showLoginSheet, onDismiss: {
            // 로그인 시트가 닫힐 때 로그인 상태 확인
            if appState.isLoggedIn, let route = pendingRoute {
                navigateTo(route)
                pendingRoute = nil
            }
        }) {
            LoginView()
        }
    }

    private func navigateWithLoginCheck(to route: HomeRoute) {
        if appState.isLoggedIn {
            navigateTo(route)
        } else {
            pendingRoute = route
            showLoginSheet = true
        }
    }

    private func navigateTo(_ route: HomeRoute) {
        navigationPath.append(route)
    }
}

// MARK: - Large Feature Card

struct LargeFeatureCard: View {
    let title: String
    let description: String
    let imageName: String
    let imageSize: CGSize
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.app(.subHeadline1))
                            .foregroundStyle(.textMain)

                        Text(description)
                            .font(.app(.subContent2))
                            .foregroundStyle(.textSub)

                        Spacer()
                    }

                    Spacer()
                }
                .padding(20)

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageSize.width, height: imageSize.height)
                    .padding(.trailing, 8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Small Feature Card

struct SmallFeatureCard: View {
    let title: String
    let description: String
    let imageName: String
    let imageSize: CGSize
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.app(.subHeadline1))
                        .foregroundStyle(.textMain)

                    Text(description)
                        .font(.app(.subContent2))
                        .foregroundStyle(.textSub)
                        .lineLimit(2)

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)

                ZStack {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imageSize.width, height: imageSize.height)
                }
                .frame(width: 80, height: 80)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Trending Meeting Card

struct TrendingMeetingCard: View {
    let imageName: String
    let title: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 280, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(title)
                .font(.app(.subHeadline2))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .padding(16)
        }
        .frame(width: 280, height: 160)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
