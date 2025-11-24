//
//  ChatListView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/10/25.
//

import SwiftUI
import Kingfisher

// MARK: - 채팅 리스트 화면

/// 채팅방 목록 화면
struct ChatListView: View {
    // MARK: - Properties

    @StateObject private var store = ChatListStore()
    @State private var navigationPath = NavigationPath()

    // MARK: - Body

    var body: some View {
        ZStack {
                // 전체 배경색
                Color.wmBg
                    .ignoresSafeArea(.all)

                VStack {
                    if store.state.isLoading {
                        loadingView
                    } else if let errorMessage = store.state.errorMessage {
                        errorView(errorMessage)
                    } else if store.state.isEmpty {
                        emptyView
                    } else {
                        chatRoomListView
                    }
                }
            }
            .navigationTitle("채팅")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: ChatRoom.self) { room in
                ChatDetailView(room: room)
            }
            .onAppear {
                if store.state.chatRooms.isEmpty {
                    store.handle(.loadChatRooms)
                }
            }
            .onDisappear {
                print("🔌 채팅 목록에서 나감 - WebSocket 연결 유지")
                // Socket 연결은 유지 - 실시간 업데이트를 위해
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)) { _ in
                ChatSocketIOManager.shared.closeWebSocket()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                print("📱 앱이 백그라운드로 이동 - WebSocket 연결 유지")
            }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack {
            ProgressView("채팅방을 불러오는 중...")
                .padding()
            Spacer()
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text("오류가 발생했습니다")
                .font(.headline)
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("다시 시도") {
                store.handle(.retryLoadChatRooms)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "message")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("채팅방이 없습니다")
                .font(.headline)
                .foregroundColor(.gray)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var chatRoomListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(store.state.filteredChatRooms) { room in
                    ChatRoomRow(room: room)
                        .buttonWrapper {
                            navigationPath.append(room)
                        }

                    // 구분선
                    if room.id != store.state.filteredChatRooms.last?.id {
                        Divider()
                            .padding(.leading, 68)
                    }
                }
            }
        }
        .refreshable {
            store.handle(.refreshChatRooms)
            // 새로고침이 완료될 때까지 기다리기
            while store.state.isRefreshing {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초
            }
        }
    }
}

// MARK: - Chat Room Row

/// 채팅방 행 컴포넌트
struct ChatRoomRow: View {
    let room: ChatRoom

    var body: some View {
        HStack(spacing: Spacing.medium) {
            // 프로필 이미지
            profileImage

            // 채팅 정보
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                // 상단: 이름 + 시간
                HStack {
                    Text(room.otherUser?.nickname ?? "알 수 없음")
                        .font(.app(.subHeadline2))
                        .foregroundStyle(.textMain)

                    Spacer()

                    Text(room.lastChatTime)
                        .font(.app(.subContent2))
                        .foregroundStyle(.textSub)
                }

                // 하단: 마지막 메시지
                HStack(spacing: Spacing.xSmall) {
                    if let lastChat = room.lastChat {
                        if lastChat.hasMedia {
                            Image(systemName: "photo")
                                .font(.system(size: 12))
                                .foregroundStyle(.textSub)
                        }

                        Text(lastChat.content)
                            .font(.app(.content2))
                            .foregroundStyle(.textSub)
                            .lineLimit(1)
                    } else {
                        Text("메시지 없음")
                            .font(.app(.content2))
                            .foregroundStyle(.textSub)
                    }

                    Spacer()
                }
            }
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.medium)
        .background(.wmBg)
    }

    // MARK: - Subviews

    /// 프로필 이미지
    private var profileImage: some View {
        Group {
            if let profileURL = room.otherUser?.profileImageURL,
               let url = URL(string: profileURL) {
                KFImage(url)
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.gray)
                            .font(.system(size: 26))
                    }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ChatListView()
}
