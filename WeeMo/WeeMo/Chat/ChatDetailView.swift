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

    let room: ChatRoom

    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 메시지 목록
            ScrollView {
                LazyVStack(spacing: Spacing.medium) {
                    ForEach(messages) { message in
                        ChatBubble(
                            message: message,
                            isMine: message.isMine(currentUserId: MockChatData.currentUser.userId)
                        )
                    }
                }
                .padding(.horizontal, Spacing.base)
                .padding(.vertical, Spacing.medium)
            }
            .background(.wmBg)

            // 입력창
            messageInputBar
        }
        .navigationTitle(room.otherUser?.nickname ?? "채팅")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMessages()
        }
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
            TextField("메시지를 입력하세요", text: $inputText)
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
                .foregroundStyle(inputText.isEmpty ? .textSub : .wmMain)
                .buttonWrapper {
                    sendMessage()
                }
            .disabled(inputText.isEmpty)
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

    // MARK: - Helper Methods

    /// 메시지 로드
    private func loadMessages() {
        messages = MockChatData.messages(for: room.id)
    }

    /// 메시지 전송
    private func sendMessage() {
        guard !inputText.isEmpty else { return }

        let newMessage = ChatMessage(
            id: UUID().uuidString,
            roomId: room.id,
            content: inputText,
            createdAt: Date(),
            sender: MockChatData.currentUser,
            files: []
        )

        messages.append(newMessage)
        inputText = ""

        // TODO: API 전송
        print("메시지 전송: \(newMessage.content)")
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
                Spacer(minLength: 60)
                timeLabel
                messageContent
            } else {
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
                    .foregroundStyle(.textMain)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .background(
                        RoundedRectangle(cornerRadius: Spacing.radiusMedium)
                            .fill(isMine ? .wmGray : Color.gray.opacity(0.1))
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
        ChatDetailView(room: MockChatData.chatRooms[0])
    }
}
