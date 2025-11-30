//
//  ChatsWidgetLiveActivity.swift
//  ChatsWidget
//
//  Created by 차지용 on 11/30/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

// Widget Extension용 Live Activity 타입 정의
struct WidgetChatLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var latestMessage: String
        var senderName: String
        var unreadCount: Int
        var lastMessageTime: Date
        var isTyping: Bool

        init(
            latestMessage: String,
            senderName: String,
            unreadCount: Int,
            lastMessageTime: Date = Date(),
            isTyping: Bool = false
        ) {
            self.latestMessage = latestMessage
            self.senderName = senderName
            self.unreadCount = unreadCount
            self.lastMessageTime = lastMessageTime
            self.isTyping = isTyping
        }
    }

    var chatRoomId: String
    var chatRoomTitle: String
    var isGroupChat: Bool

    init(chatRoomId: String, chatRoomTitle: String, isGroupChat: Bool = false) {
        self.chatRoomId = chatRoomId
        self.chatRoomTitle = chatRoomTitle
        self.isGroupChat = isGroupChat
    }
}

// 타입 별칭으로 동일한 이름 사용
typealias ChatLiveActivityAttributes = WidgetChatLiveActivityAttributes

struct ChatsWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ChatLiveActivityAttributes.self) { context in
            ChatLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ChatExpandedLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ChatExpandedTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ChatExpandedBottomView(context: context)
                }
            } compactLeading: {
                ChatCompactLeadingView(context: context)
            } compactTrailing: {
                ChatCompactTrailingView(context: context)
            } minimal: {
                ChatMinimalView(context: context)
            }
            .widgetURL(URL(string: "weemo://chat/\(context.attributes.chatRoomId)"))
            .keylineTint(.blue)
        }
    }
}

// MARK: - 잠금화면 뷰
struct ChatLockScreenView: View {
    let context: ActivityViewContext<ChatLiveActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(context.attributes.chatRoomTitle.prefix(1)))
                            .font(.headline)
                            .foregroundColor(.blue)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(context.attributes.chatRoomTitle)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(formatTime(context.state.lastMessageTime))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if context.state.isTyping {
                    Text("\(context.state.senderName)님이 입력 중...")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .italic()
                } else {
                    Text("\(context.state.senderName): \(context.state.latestMessage)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            if context.state.unreadCount > 0 {
                Text("\(context.state.unreadCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .clipShape(Circle())
            }
        }
        .padding()
        .activityBackgroundTint(Color(.systemBackground))
        .activitySystemActionForegroundColor(.primary)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Dynamic Island 뷰들
struct ChatExpandedLeadingView: View {
    let context: ActivityViewContext<ChatLiveActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(context.attributes.chatRoomTitle)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)

            if context.state.isTyping {
                Text("입력 중...")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .italic()
            } else {
                Text(context.state.senderName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

struct ChatExpandedTrailingView: View {
    let context: ActivityViewContext<ChatLiveActivityAttributes>

    var body: some View {
        VStack(spacing: 4) {
            if context.state.unreadCount > 0 {
                Text("\(context.state.unreadCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .clipShape(Circle())

                Text("새 메시지")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)

                Text("읽음")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ChatExpandedBottomView: View {
    let context: ActivityViewContext<ChatLiveActivityAttributes>

    var body: some View {
        VStack(spacing: 8) {
            if context.state.isTyping {
                HStack {
                    Text("💬")
                    Text("\(context.state.senderName)님이 메시지를 입력하고 있습니다")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    Text("💬")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.latestMessage)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)

                        Text(formatDetailedTime(context.state.lastMessageTime))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
        }
        .padding(.horizontal)
    }

    private func formatDetailedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct ChatCompactLeadingView: View {
    let context: ActivityViewContext<ChatLiveActivityAttributes>

    var body: some View {
        Image(systemName: "message.fill")
            .foregroundColor(.blue)
            .font(.system(size: 14, weight: .medium))
    }
}

struct ChatCompactTrailingView: View {
    let context: ActivityViewContext<ChatLiveActivityAttributes>

    var body: some View {
        HStack(spacing: 4) {
            if context.state.isTyping {
                Text("...")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
            } else if context.state.unreadCount > 0 {
                Text("\(min(context.state.unreadCount, 99))")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .clipShape(Circle())
            }
        }
    }
}

struct ChatMinimalView: View {
    let context: ActivityViewContext<ChatLiveActivityAttributes>

    var body: some View {
        if context.state.isTyping {
            Text("...")
                .font(.caption2)
                .foregroundColor(.blue)
                .fontWeight(.bold)
        } else if context.state.unreadCount > 0 {
            Text("\(min(context.state.unreadCount, 9))")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(Color.red)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
        }
    }
}

// MARK: - Preview
extension ChatLiveActivityAttributes {
    static var preview: ChatLiveActivityAttributes {
        ChatLiveActivityAttributes(
            chatRoomId: "test-room",
            chatRoomTitle: "다진홍차",
            isGroupChat: false
        )
    }
}

extension ChatLiveActivityAttributes.ContentState {
    static var previewMessage: ChatLiveActivityAttributes.ContentState {
        ChatLiveActivityAttributes.ContentState(
            latestMessage: "안녕하세요! 오늘 날씨가 정말 좋네요. 산책 어떠세요?",
            senderName: "다진홍차",
            unreadCount: 3,
            lastMessageTime: Date(),
            isTyping: false
        )
    }

    static var previewTyping: ChatLiveActivityAttributes.ContentState {
        ChatLiveActivityAttributes.ContentState(
            latestMessage: "네, 좋은 생각이에요!",
            senderName: "다진홍차",
            unreadCount: 2,
            lastMessageTime: Date().addingTimeInterval(-60),
            isTyping: true
        )
    }
}

#Preview("Live Activity", as: .content, using: ChatLiveActivityAttributes.preview) {
    ChatsWidgetLiveActivity()
} contentStates: {
    ChatLiveActivityAttributes.ContentState.previewMessage
    ChatLiveActivityAttributes.ContentState.previewTyping
}
