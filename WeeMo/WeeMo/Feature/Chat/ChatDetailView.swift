//
//  ChatDetailView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/10/25.
//

import SwiftUI
import Kingfisher

// MARK: - 채팅 상세 화면

/// 채팅방 상세 화면 (메시지 목록 + 입력창)
struct ChatDetailView: View {
    // MARK: - Properties

    @StateObject private var store: ChatDetailStore
    @Environment(\.dismiss) private var dismiss

    init(room: ChatRoom) {
        self._store = StateObject(wrappedValue: ChatDetailStore(room: room))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 메시지 목록
            messageListView

            // 에러 메시지
            if let errorMessage = store.state.errorMessage {
                errorView(errorMessage)
            }

            // 입력창
            messageInputBar
        }
        .background(.wmBg)
        .navigationTitle(store.state.room.otherUser?.nickname ?? "채팅")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // 30일 이내 메시지 정리 (한 번만 실행)
            store.cleanupRecentMessages()

            store.handle(.loadMessages(roomId: store.state.room.id))
            store.handle(.setupSocketConnection(roomId: store.state.room.id))
        }
        .onDisappear {
            // Socket 연결은 유지하되 다른 화면 이동을 로깅
            print("🔌 ChatDetailView onDisappear - 연결 유지")
        }
    }

    // MARK: - Subviews

    private var messageListView: some View {
        ScrollViewReader { proxy in
            if store.state.isLoading && store.state.messages.isEmpty {
                // 로딩 상태
                VStack(spacing: Spacing.medium) {
                    Spacer()

                    VStack(spacing: Spacing.small) {
                        ProgressView()
                            .scaleEffect(1.2)

                        Text("메시지를 불러오는 중...")
                            .font(.app(.content2))
                            .foregroundColor(.textSub)
                    }

                    Spacer()
                }

            } else if store.state.messages.isEmpty {
                // 빈 상태
                VStack(spacing: Spacing.medium) {
                    Spacer()

                    VStack(spacing: Spacing.small) {
                        Image(systemName: "message")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.6))

                        Text("대화를 시작해보세요")
                            .font(.app(.headline1))
                            .foregroundColor(.textMain)

                        Text("첫 메시지를 보내서 대화를 시작할 수 있어요")
                            .font(.app(.content2))
                            .foregroundColor(.textSub)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                }

            } else {
                // 메시지가 있는 경우
                ScrollView {
                    LazyVStack(spacing: Spacing.medium) {
                        // 상단 로딩 인디케이터
                        if store.state.hasMoreMessages {
                            VStack {
                                if store.state.isLoadingMore {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("이전 메시지 불러오는 중...")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, Spacing.small)
                                }
                            }
                            .frame(height: 50)
                            .onAppear {
                                if !store.state.isLoadingMore,
                                   let firstMessage = store.state.messages.first {
                                    print("🔄 스크롤 상단 도달 - 이전 메시지 로드 시작")
                                    store.handle(.loadMoreMessages(beforeMessageId: firstMessage.id))
                                }
                            }
                            .id("loadMoreTrigger")
                        }

                        // 메시지 목록
                        ForEach(store.state.messages) { message in
                            ChatBubble(
                                message: message,
                                isMine: message.isMine(currentUserId: store.state.currentUserId)
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, Spacing.base)
                    .padding(.vertical, Spacing.medium)
                }
                .refreshable {
                    if store.state.hasMoreMessages,
                       !store.state.isLoadingMore,
                       let firstMessage = store.state.messages.first {
                        print("🔄 Pull to refresh - 이전 메시지 로드 시작")
                        store.handle(.loadMoreMessages(beforeMessageId: firstMessage.id))
                    }
                }
                .onChange(of: store.state.messages.count) { _, _ in
                    guard !store.state.messages.isEmpty else { return }
                    if let lastMessage = store.state.messages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: store.state.shouldScrollToBottom) { _, shouldScroll in
                    if shouldScroll, let lastMessage = store.state.messages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        HStack {
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
            Spacer()
            Button("재시도") {
                store.handle(.retryLoadMessages)
            }
            .font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.1))
    }


    // MARK: - Subviews

    /// 메시지 입력창
    private var messageInputBar: some View {
        HStack(spacing: Spacing.small) {
            // 이미지 추가 버튼
            Image(systemName: "photo")
                .font(.system(size: 24))
                .foregroundStyle(.textSub)
                .buttonWrapper {
                    // TODO: 이미지 선택
                    print("이미지 추가")
                }

            // 텍스트 입력
            TextField("메시지를 입력하세요", text: $store.state.inputText)
                .font(.app(.content2))
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                        .fill(Color.gray.opacity(0.1))
                )

            // 전송 버튼
            Image(systemName: "paperplane.fill")
                .font(.system(size: 20))
                .foregroundStyle(store.state.canSendMessage ? .wmMain : .textSub)
                .buttonWrapper {
                    if store.state.canSendMessage {
                        store.handle(.sendMessage(content: store.state.inputText))
                    }
                }
                .disabled(!store.state.canSendMessage || store.state.isSendingMessage)
        }
        .padding(.horizontal, Spacing.base)
        .padding(.vertical, Spacing.small)
        .background(.wmBg)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(Color.gray.opacity(0.3)),
            alignment: .top
        )
    }

}

// MARK: - Chat Bubble Component

/// 채팅 말풍선 컴포넌트
//TODO: - 모서리 말풍선 이미지 적용 ?
struct ChatBubble: View {
    let message: ChatMessage
    let isMine: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.small) {
            if isMine {
                // 내 메시지: 오른쪽 정렬
                Spacer(minLength: 60)
                timeLabel
                messageContent
            } else {
                // 상대방 메시지: 왼쪽 정렬
                profileImage
                messageContent
                timeLabel
                Spacer(minLength: 60)
            }
        }
    }

    // MARK: - Subviews

    /// 프로필 이미지 (상대방만)
    @ViewBuilder
    private var profileImage: some View {
        if !isMine {
                if let profileURL = message.sender.profileImageURL,
                   let url = URL(string: profileURL) {
                    KFImage(url)
                        .placeholder {
                            Circle().fill(Color.gray.opacity(0.3))
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.gray)
                                .font(.system(size: 16))
                        }
                }
        }
    }

    /// 메시지 내용
    @ViewBuilder
    private var messageContent: some View {
        VStack(alignment: isMine ? .trailing : .leading, spacing: Spacing.xSmall) {
            // 이미지가 있으면 표시
            if message.hasMedia {
                ForEach(message.files, id: \.self) { fileURL in
                    if let url = URL(string: fileURL) {
                        KFImage(url)
                            .placeholder {
                                RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 200, height: 150)
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: 200, maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: Spacing.radiusMedium))
                    }
                }
            }

            // 텍스트 메시지
            if !message.content.isEmpty {
                Text(message.content)
                    .font(.app(.content2))
                    .foregroundStyle(isMine ? .white : .textMain)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                            .fill(isMine ? Color.wmMain : Color.gray.opacity(0.1))
                    )
            }
        }
    }

    /// 시간 라벨
    private var timeLabel: some View {
        Text(message.createdAt.chatTimeString())
            .font(.app(.subContent2))
            .foregroundStyle(.textSub)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        let sampleRoom = ChatRoom(
            id: "sample-room-id",
            participants: [
                User(userId: "user1", nickname: "사용자1", profileImageURL: nil),
                User(userId: "user2", nickname: "사용자2", profileImageURL: nil)
            ],
            lastChat: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        ChatDetailView(room: sampleRoom)
    }
}
