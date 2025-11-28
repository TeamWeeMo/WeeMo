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
}

enum MainScreen {
    case home
    case profile
    case chatList
}

struct HomeView: View {

    @EnvironmentObject var appState: AppState
    @State private var showSideMenu = false
    @State private var navigationPath = NavigationPath()
    @State private var currentScreen: MainScreen = .home

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // 현재 선택된 메인 화면
                Group {
                    switch currentScreen {
                    case .home:
                        homeContent
                    case .profile:
                        ProfileView()
                    case .chatList:
                        ChatListView()
                            .navigationBarHidden(true)
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: currentScreen)

                // Dark Overlay
                if showSideMenu {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showSideMenu = false
                            }
                        }
                }

                // Side Menu
                SideMenuView(
                    isShowing: $showSideMenu,
                    onMenuClose: {
                        withAnimation {
                            showSideMenu = false
                        }
                        // 메뉴 닫힌 후 화면 전환
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            currentScreen = .home
                        }
                    },
                    onProfileTap: {
                        withAnimation {
                            showSideMenu = false
                        }
                        // 메뉴 닫힌 후 화면 전환
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            currentScreen = .profile
                        }
                    },
                    onChatTap: {
                        withAnimation {
                            showSideMenu = false
                        }
                        // 메뉴 닫힌 후 화면 전환
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            currentScreen = .chatList
                        }
                    }
                )

                // Floating Hamburger Button
                VStack {
                    HStack {
                        Spacer()

                        Button {
                            withAnimation {
                                showSideMenu.toggle()
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 24))
                                .foregroundStyle(.textMain)
                                .padding(12)
                                .background(.white)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 12)
                    }

                    Spacer()
                }
            }
            .onChange(of: currentScreen) { oldValue, newValue in
                // 채팅 화면에서 다른 화면으로 이동할 때 소켓 연결 해제
                if oldValue == .chatList && newValue != .chatList {
                    print("HomeView - 채팅에서 다른 화면으로 이동, 소켓 연결 해제")
                    ChatSocketIOManager.shared.closeWebSocket()
                }
            }
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
                }
            }
            .navigationDestination(for: Space.self) { space in
                SpaceDetailView(space: space)
            }
            .navigationDestination(for: ChatRoom.self) { room in
                ChatDetailView(room: room)
            }
            .navigationDestination(for: String.self) { value in
                if value == "map" {
                    MeetMapView()
                } else if value == "edit" {
                    MeetEditView()
                } else if value.hasPrefix("edit:") {
                    // "edit:postId" 형식으로 전달된 경우
                    let postId = String(value.dropFirst(5))
                    MeetEditView(editingPostId: postId)
                } else {
                    MeetDetailView(postId: value)
                }
            }
        }
    }

    // MARK: - Home Content

    private var homeContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack(spacing: 4) {
                    Image("WeeMoLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 20)

                    Text("WeeMo")
                        .font(.app(.headline2))
                        .foregroundStyle(.black)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                // Main Feature Cards
                VStack(spacing: 16) {
                    // 모임 찾기 (큰 카드)
                    NavigationLink(value: HomeRoute.meetList) {
                        LargeFeatureCardContent(
                            title: "모임 찾기",
                            description: "내 근처에 있는 모임 구경하기",
                            imageName: "person",
                            imageSize: CGSize(width: 88, height: 88)
                        )
                    }

                    HStack(spacing: 16) {
                        // 모임 등록하기 (작은 카드)
                        NavigationLink(value: HomeRoute.meetEdit) {
                            SmallFeatureCardContent(
                                title: "모임 등록하기",
                                description: "모임장 되어 시람 모으기",
                                imageName: "pencil",
                                imageSize: CGSize(width: 80, height: 80)
                            )
                        }

                        // 공간 찾기 (작은 카드)
                        NavigationLink(value: HomeRoute.spaceList) {
                            SmallFeatureCardContent(
                                title: "공간 찾기",
                                description: "모이기 좋은 공간 찾기",
                                imageName: "find",
                                imageSize: CGSize(width: 70, height: 70)
                            )
                        }
                    }

                    // 피드 (큰 카드)
                    NavigationLink(value: HomeRoute.feed) {
                        LargeFeatureCardContent(
                            title: "피드",
                            description: "내 주변 시람, 관심사 확인하기",
                            imageName: "camera",
                            imageSize: CGSize(width: 88, height: 88)
                        )
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
    }
}

// MARK: - Large Feature Card Content

struct LargeFeatureCardContent: View {
    let title: String
    let description: String
    let imageName: String
    let imageSize: CGSize

    var body: some View {
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
}

// MARK: - Small Feature Card Content

struct SmallFeatureCardContent: View {
    let title: String
    let description: String
    let imageName: String
    let imageSize: CGSize

    var body: some View {
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

// MARK: - Side Menu View

struct SideMenuView: View {
    @Binding var isShowing: Bool
    let onMenuClose: () -> Void
    let onProfileTap: () -> Void
    let onChatTap: () -> Void

    var body: some View {
        GeometryReader { geometry in
            HStack {
                Spacer()

                VStack(alignment: .leading, spacing: 0) {
                    // Menu Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("메뉴")
                            .font(.app(.headline3))
                            .foregroundStyle(.textMain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 32)

                    // Menu Items
                    VStack(spacing: 0) {
                        Button {
                            onMenuClose()
                        } label: {
                            MenuItemContent(icon: "house", title: "홈")
                        }

                        Button {
                            onProfileTap()
                        } label: {
                            MenuItemContent(icon: "person.circle", title: "프로필")
                        }

                        Button {
                            onChatTap()
                        } label: {
                            MenuItemContent(icon: "message", title: "채팅")
                        }
                    }

                    Spacer()
                }
                .frame(width: geometry.size.width * 0.7)
                .background(.white)
                .offset(x: isShowing ? 0 : geometry.size.width * 0.7)
                .animation(.easeInOut(duration: 0.3), value: isShowing)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Menu Item Content

struct MenuItemContent: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(.textMain)
                .frame(width: 30)

            Text(title)
                .font(.app(.content1))
                .foregroundStyle(.textMain)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
