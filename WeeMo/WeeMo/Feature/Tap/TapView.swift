//
//  TapView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/10/25.
//

import SwiftUI

// MARK: - 메인 탭뷰

/// 앱의 메인 탭바 (5개 탭)
/// - 공간, 모임, 피드, 채팅, 프로필
struct TapView: View {
    // MARK: - Tab Definition
    
    /// 탭 종류
    enum Tab: Int, CaseIterable {
        case space = 0
        case meet = 1
        case feed = 2
        case chat = 3
        case profile = 4

        var title: String {
            switch self {
            case .space: return "공간"
            case .meet: return "모임"
            case .feed: return "피드"
            case .chat: return "채팅"
            case .profile: return "프로필"
            }
        }

        var icon: String {
            switch self {
            case .space: return "building.2"
            case .meet: return "person.3"
            case .feed: return "photo.on.rectangle.angled"
            case .chat: return "bubble.left.and.bubble.right"
            case .profile: return "person.circle"
            }
        }

        var iconFilled: String {
            switch self {
            case .space: return "building.2.fill"
            case .meet: return "person.3.fill"
            case .feed: return "photo.on.rectangle.angled"
            case .chat: return "bubble.left.and.bubble.right.fill"
            case .profile: return "person.circle.fill"
            }
        }
    }
    
    // MARK: - Properties
    
    @State private var selectedTab: Tab = .space
    
    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // 공간 탭
            SpaceListView()
                .tabItem {
                    Label(Tab.space.title, systemImage: selectedTab == .space ? Tab.space.iconFilled : Tab.space.icon)
                }
                .tag(Tab.space)
            
            // 모임 탭
            MeetListView()
                .tabItem {
                    Label(Tab.meet.title, systemImage: selectedTab == .meet ? Tab.meet.iconFilled : Tab.meet.icon)
                }
                .tag(Tab.meet)
            
            // 피드 탭
            FeedView()
                .tabItem {
                    Label(Tab.feed.title, systemImage: selectedTab == .feed ? Tab.feed.iconFilled : Tab.feed.icon)
                }
                .tag(Tab.feed)
            
            // 채팅 탭
            ChatListView()
                .tabItem {
                    Label(Tab.chat.title, systemImage: selectedTab == .chat ? Tab.chat.iconFilled : Tab.chat.icon)
                }
                .tag(Tab.chat)
            
            // 프로필 탭
            ProfileView()
                .tabItem {
                    Label(Tab.profile.title, systemImage: selectedTab == .profile ? Tab.profile.iconFilled : Tab.profile.icon)
                }
                .tag(Tab.profile)
        }
        .tint(.wmMain)
    }
}
// MARK: - Preview

#Preview {
    TapView()
}
