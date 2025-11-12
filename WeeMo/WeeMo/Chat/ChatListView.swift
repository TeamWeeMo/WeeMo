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

    @State private var chatRooms: [ChatRoom] = MockChatData.chatRooms
    @State private var selectedRoom: ChatRoom?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(chatRooms) { room in
                        ChatRoomRow(room: room)
                            .buttonWrapper {
                                selectedRoom = room
                            }

                        // 구분선
                        if room.id != chatRooms.last?.id {
                            Divider()
                                .padding(.leading, 68)
                        }
                    }
                }
            }
            .background(.wmBg)
            .navigationTitle("채팅")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $selectedRoom) { room in
                ChatDetailView(room: room)
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
