//
//  MockChatData.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/10/25.
//

import Foundation

// MARK: - Mock Chat Data

enum MockChatData {
    // MARK: - Mock Users

    static let currentUser = User(
        userId: "current_user",
        nickname: "나",
        profileImageURL: nil
    )

    static let users: [User] = [
        User(userId: "user_001", nickname: "김철수", profileImageURL: "https://picsum.photos/200?random=1"),
        User(userId: "user_002", nickname: "이영희", profileImageURL: "https://picsum.photos/200?random=2"),
        User(userId: "user_003", nickname: "박지민", profileImageURL: "https://picsum.photos/200?random=3"),
        User(userId: "user_004", nickname: "최동욱", profileImageURL: "https://picsum.photos/200?random=4"),
        User(userId: "user_005", nickname: "정수연", profileImageURL: "https://picsum.photos/200?random=5"),
        User(userId: "user_006", nickname: "강민호", profileImageURL: "https://picsum.photos/200?random=6"),
        User(userId: "user_007", nickname: "윤서아", profileImageURL: "https://picsum.photos/200?random=7"),
        User(userId: "user_008", nickname: "임준혁", profileImageURL: "https://picsum.photos/200?random=8"),
        User(userId: "user_009", nickname: "한소희", profileImageURL: nil),
        User(userId: "user_010", nickname: "장우진", profileImageURL: "https://picsum.photos/200?random=10")
    ]

    // MARK: - Mock Chat Rooms

    static let chatRooms: [ChatRoom] = [
        ChatRoom(
            id: "room_001",
            participants: [users[0]],
            lastChat: ChatMessage(
                id: "msg_001",
                roomId: "room_001",
                content: "오늘 저녁에 모임 어때요?",
                createdAt: Date().addingTimeInterval(-300),
                sender: users[0],
                files: []
            ),
            createdAt: Date().addingTimeInterval(-86400),
            updatedAt: Date().addingTimeInterval(-300)
        ),
        ChatRoom(
            id: "room_002",
            participants: [users[1]],
            lastChat: ChatMessage(
                id: "msg_002",
                roomId: "room_002",
                content: "사진 공유해드릴게요!",
                createdAt: Date().addingTimeInterval(-1800),
                sender: users[1],
                files: ["https://picsum.photos/400?random=20"]
            ),
            createdAt: Date().addingTimeInterval(-172800),
            updatedAt: Date().addingTimeInterval(-1800)
        ),
        ChatRoom(
            id: "room_003",
            participants: [users[2]],
            lastChat: ChatMessage(
                id: "msg_003",
                roomId: "room_003",
                content: "네 알겠습니다 👍",
                createdAt: Date().addingTimeInterval(-3600),
                sender: currentUser,
                files: []
            ),
            createdAt: Date().addingTimeInterval(-259200),
            updatedAt: Date().addingTimeInterval(-3600)
        ),
        ChatRoom(
            id: "room_004",
            participants: [users[3]],
            lastChat: ChatMessage(
                id: "msg_004",
                roomId: "room_004",
                content: "공간 예약 완료했어요",
                createdAt: Date().addingTimeInterval(-7200),
                sender: users[3],
                files: []
            ),
            createdAt: Date().addingTimeInterval(-345600),
            updatedAt: Date().addingTimeInterval(-7200)
        ),
        ChatRoom(
            id: "room_005",
            participants: [users[4]],
            lastChat: ChatMessage(
                id: "msg_005",
                roomId: "room_005",
                content: "감사합니다!",
                createdAt: Date().addingTimeInterval(-14400),
                sender: users[4],
                files: []
            ),
            createdAt: Date().addingTimeInterval(-432000),
            updatedAt: Date().addingTimeInterval(-14400)
        ),
        ChatRoom(
            id: "room_006",
            participants: [users[5]],
            lastChat: ChatMessage(
                id: "msg_006",
                roomId: "room_006",
                content: "다음 주에 뵙겠습니다",
                createdAt: Date().addingTimeInterval(-28800),
                sender: currentUser,
                files: []
            ),
            createdAt: Date().addingTimeInterval(-518400),
            updatedAt: Date().addingTimeInterval(-28800)
        ),
        ChatRoom(
            id: "room_007",
            participants: [users[6]],
            lastChat: ChatMessage(
                id: "msg_007",
                roomId: "room_007",
                content: "좋은 하루 되세요!",
                createdAt: Date().addingTimeInterval(-43200),
                sender: users[6],
                files: []
            ),
            createdAt: Date().addingTimeInterval(-604800),
            updatedAt: Date().addingTimeInterval(-43200)
        ),
        ChatRoom(
            id: "room_008",
            participants: [users[7]],
            lastChat: ChatMessage(
                id: "msg_008",
                roomId: "room_008",
                content: "문의사항이 있는데요",
                createdAt: Date().addingTimeInterval(-86400),
                sender: users[7],
                files: []
            ),
            createdAt: Date().addingTimeInterval(-691200),
            updatedAt: Date().addingTimeInterval(-86400)
        ),
        ChatRoom(
            id: "room_009",
            participants: [users[8]],
            lastChat: ChatMessage(
                id: "msg_009",
                roomId: "room_009",
                content: "반갑습니다 :)",
                createdAt: Date().addingTimeInterval(-172800),
                sender: users[8],
                files: []
            ),
            createdAt: Date().addingTimeInterval(-777600),
            updatedAt: Date().addingTimeInterval(-172800)
        ),
        ChatRoom(
            id: "room_010",
            participants: [users[9]],
            lastChat: ChatMessage(
                id: "msg_010",
                roomId: "room_010",
                content: "확인했습니다",
                createdAt: Date().addingTimeInterval(-259200),
                sender: currentUser,
                files: []
            ),
            createdAt: Date().addingTimeInterval(-864000),
            updatedAt: Date().addingTimeInterval(-259200)
        )
    ]

    // MARK: - Mock Messages for Detail View

    /// 특정 채팅방의 메시지 목록 생성
    static func messages(for roomId: String) -> [ChatMessage] {
        guard let room = chatRooms.first(where: { $0.id == roomId }),
              let otherUser = room.otherUser else {
            return []
        }

        return [
            ChatMessage(
                id: "\(roomId)_msg_1",
                roomId: roomId,
                content: "안녕하세요!",
                createdAt: Date().addingTimeInterval(-86400),
                sender: otherUser,
                files: []
            ),
            ChatMessage(
                id: "\(roomId)_msg_2",
                roomId: roomId,
                content: "네, 안녕하세요 😊",
                createdAt: Date().addingTimeInterval(-86340),
                sender: currentUser,
                files: []
            ),
            ChatMessage(
                id: "\(roomId)_msg_3",
                roomId: roomId,
                content: "위모 앱 정말 좋네요",
                createdAt: Date().addingTimeInterval(-85000),
                sender: otherUser,
                files: []
            ),
            ChatMessage(
                id: "\(roomId)_msg_4",
                roomId: roomId,
                content: "감사합니다!",
                createdAt: Date().addingTimeInterval(-84900),
                sender: currentUser,
                files: []
            ),
            ChatMessage(
                id: "\(roomId)_msg_5",
                roomId: roomId,
                content: room.lastChat?.content ?? "마지막 메시지",
                createdAt: room.lastChat?.createdAt ?? Date(),
                sender: room.lastChat?.sender ?? otherUser,
                files: room.lastChat?.files ?? []
            )
        ]
    }
}

// MARK: - Date Extension (시간 표시)
//TODO: - Date Extension 분리 필요
extension Date {
    /// 상대 시간 문자열 ("방금 전", "3분 전", "어제", "2024.05.06")
    func chatTimeAgoString() -> String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)

        if let minute = components.minute, minute < 1 {
            return "방금 전"
        } else if let minute = components.minute, minute < 60 {
            return "\(minute)분 전"
        } else if let hour = components.hour, hour < 24 {
            return "\(hour)시간 전"
        } else if let day = components.day, day == 1 {
            return "어제"
        } else if let day = components.day, day < 7 {
            return "\(day)일 전"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy.MM.dd"
            return formatter.string(from: self)
        }
    }

    /// 채팅 메시지용 시간 표시 ("오후 3:24")
    func chatTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a h:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self)
    }
}
