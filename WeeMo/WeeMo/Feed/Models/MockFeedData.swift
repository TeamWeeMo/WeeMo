//
//  MockFeedData.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/8/25.
//

import Foundation

// MARK: - Mock Feed 데이터

struct MockFeedData {
    static let sampleFeeds: [FeedItem] = [
        FeedItem(
            id: "1",
            imageURL: "https://picsum.photos/400/600",
            content: "강남역 근처 조용한 카페에서 스터디 모임 하실 분 구해요! 🌟 주 3회 저녁 7시부터 10시까지",
            creator: FeedCreator(
                userId: "user1",
                nickname: "스터디러버",
                profileImageURL: "https://i.pravatar.cc/150?img=1"
            ),
            createdAt: Date().addingTimeInterval(-3600),
            likes: ["user2", "user3"],
            commentCount: 5
        ),
        FeedItem(
            id: "2",
            imageURL: "https://picsum.photos/400/700",
            content: "홍대 루프탑 공간 대여 가능합니다! 파티, 모임, 촬영 등 다양하게 활용 가능해요",
            creator: FeedCreator(
                userId: "user2",
                nickname: "공간매니저",
                profileImageURL: "https://i.pravatar.cc/150?img=2"
            ),
            createdAt: Date().addingTimeInterval(-7200),
            likes: ["user1"],
            commentCount: 3
        ),
        FeedItem(
            id: "3",
            imageURL: "https://picsum.photos/400/500",
            content: "주말 등산 모임 🏔️ 북한산 코스 함께 가실 분!",
            creator: FeedCreator(
                userId: "user3",
                nickname: "산악회장",
                profileImageURL: "https://i.pravatar.cc/150?img=3"
            ),
            createdAt: Date().addingTimeInterval(-10800),
            likes: ["user1", "user2", "user4"],
            commentCount: 12
        ),
        FeedItem(
            id: "4",
            imageURL: "https://picsum.photos/400/650",
            content: "코딩 스터디 멤버 모집합니다 💻 SwiftUI 함께 공부해요",
            creator: FeedCreator(
                userId: "user4",
                nickname: "iOS개발자",
                profileImageURL: "https://i.pravatar.cc/150?img=4"
            ),
            createdAt: Date().addingTimeInterval(-14400),
            likes: ["user5"],
            commentCount: 8
        ),
        FeedItem(
            id: "5",
            imageURL: "https://picsum.photos/400/550",
            content: "강남 세미나실 시간당 대여 가능! 최대 20명 수용 가능합니다",
            creator: FeedCreator(
                userId: "user5",
                nickname: "공간셰어",
                profileImageURL: "https://i.pravatar.cc/150?img=5"
            ),
            createdAt: Date().addingTimeInterval(-18000),
            likes: [],
            commentCount: 2
        ),
        FeedItem(
            id: "6",
            imageURL: "https://picsum.photos/400/720",
            content: "요가 모임 🧘‍♀️ 초보자 환영! 매주 화요일 저녁 7시 홍대에서 만나요",
            creator: FeedCreator(
                userId: "user6",
                nickname: "요가마스터",
                profileImageURL: "https://i.pravatar.cc/150?img=6"
            ),
            createdAt: Date().addingTimeInterval(-21600),
            likes: ["user1", "user3", "user5", "user7"],
            commentCount: 15
        ),
        FeedItem(
            id: "7",
            imageURL: "https://picsum.photos/400/480",
            content: "북카페 공간 대여 📚 조용한 분위기에서 독서 모임하기 좋아요",
            creator: FeedCreator(
                userId: "user7",
                nickname: "책벌레",
                profileImageURL: "https://i.pravatar.cc/150?img=7"
            ),
            createdAt: Date().addingTimeInterval(-25200),
            likes: ["user2", "user4"],
            commentCount: 4
        ),
        FeedItem(
            id: "8",
            imageURL: "https://picsum.photos/400/620",
            content: "주말 보드게임 모임 🎲 신림역 근처 보드게임 카페에서!",
            creator: FeedCreator(
                userId: "user8",
                nickname: "게임러버",
                profileImageURL: "https://i.pravatar.cc/150?img=8"
            ),
            createdAt: Date().addingTimeInterval(-28800),
            likes: ["user1", "user6"],
            commentCount: 9
        ),
        FeedItem(
            id: "9",
            imageURL: "https://picsum.photos/400/580",
            content: "사진 스터디 📸 DSLR, 미러리스 카메라 가지고 계신 분들 모여요!",
            creator: FeedCreator(
                userId: "user9",
                nickname: "포토그래퍼",
                profileImageURL: "https://i.pravatar.cc/150?img=9"
            ),
            createdAt: Date().addingTimeInterval(-32400),
            likes: ["user3", "user7", "user8"],
            commentCount: 11
        ),
        FeedItem(
            id: "10",
            imageURL: "https://picsum.photos/400/670",
            content: "영어회화 스터디 🗣️ 주 2회 카페에서 프리토킹 하실 분!",
            creator: FeedCreator(
                userId: "user10",
                nickname: "English스피커",
                profileImageURL: "https://i.pravatar.cc/150?img=10"
            ),
            createdAt: Date().addingTimeInterval(-36000),
            likes: ["user2", "user5", "user9"],
            commentCount: 7
        )
    ]
}
