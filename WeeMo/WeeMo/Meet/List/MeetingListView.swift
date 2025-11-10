//
//  MeetingListView.swift
//  WeeMo
//
//  Created by 차지용 on 11/7/25.
//

import SwiftUI

struct MeetingListView: View {
    @State private var searchText = ""
    @State private var selectedSortOption: SortOption = .registrationDate
    @State private var showingSortOptions = false

    @State private var meetings = [
        Meeting(
            title: "주말 독서 모임",
            date: "📅 2025.11.15 (토) 14:00",
            location: "📍 모던 카페 라운",
            address: "서울 강남구 테헤란로 123",
            price: "💰 15,000원/",
            participants: "👤 4 / 8명",
            imageName: "meeting1",
            daysLeft: "D-3"
        ),
        Meeting(
            title: "요리 클래스",
            date: "📅 2025.11.20 (수) 19:00",
            location: "📍 쿠킹 스튜디오 키친",
            address: "서울 마포구 홍대입구역 56",
            price: "💰 35,000원/",
            participants: "👤 6 / 10명",
            imageName: "meeting2",
            daysLeft: "D-8"
        ),
        Meeting(
            title: "등산 동호회",
            date: "📅 2025.11.17 (일) 08:00",
            location: "📍 북한산 입구",
            address: "서울 은평구 진관동 산1",
            price: "💰 무료",
            participants: "👤 12 / 15명",
            imageName: "meeting3",
            daysLeft: "D-5"
        ),
        Meeting(
            title: "보드게임 카페",
            date: "📅 2025.11.22 (금) 20:00",
            location: "📍 게임톡톡 강남점",
            address: "서울 강남구 역삼동 678",
            price: "💰 8,000원/",
            participants: "👤 3 / 6명",
            imageName: "meeting4",
            daysLeft: "D-10"
        ),
        Meeting(
            title: "사진 촬영 워크숍",
            date: "📅 2025.11.25 (월) 15:00",
            location: "📍 한강공원 반포지구",
            address: "서울 서초구 반포동 한강공원",
            price: "💰 25,000원/",
            participants: "👤 8 / 12명",
            imageName: "meeting5",
            daysLeft: "D-13"
        ),
        Meeting(
            title: "영화 토론 모임",
            date: "📅 2025.11.18 (월) 18:30",
            location: "📍 씨네큐브 광화문",
            address: "서울 종로구 세종대로 175",
            price: "💰 12,000원/",
            participants: "👤 7 / 10명",
            imageName: "meeting6",
            daysLeft: "D-6"
        )
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    HStack {
                        Text("모임")
                            .font(.app(.headline2))
                            .foregroundColor(Color("textMain"))
                            .padding(.leading, 16)
                        Spacer()
                    }
                    .padding(.top)

                    SearchBar(text: $searchText)

                    FilterButton(
                        selectedOption: $selectedSortOption,
                        showingOptions: $showingSortOptions
                    )

                    LazyVStack(spacing: 16) {
                        ForEach(meetings) { meeting in
                            NavigationLink(destination: MeetingDetailView(meeting: meeting)) {
                                MeetingCardView(meeting: meeting)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationBarHidden(true)
            .background(Color("wmBg"))
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            MapViewButton()
                            FloatingActionButton()
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            )

        }
    }
}

#Preview {
    MeetingListView()
}
