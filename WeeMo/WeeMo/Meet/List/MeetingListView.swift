//
//  MeetingListView.swift
//  WeeMo
//
//  Created by 차지용 on 11/7/25.
//

import SwiftUI

enum SortOption: String, CaseIterable {
    case registrationDate = "등록일순"
    case deadline = "마감일순"
    case distance = "가까운 순"
}

struct Meeting: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let location: String
    let address: String
    let price: String
    let participants: String
    let imageName: String
    let daysLeft: String
}

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

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 8)

            TextField("모임을 검색하세요", text: $text)
                .font(.app(.content2))
                .padding(.vertical, 8)
                .padding(.trailing, 8)

            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 8)
            }
        }
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.leading, 16)
    }
}

struct FilterButton: View {
    @Binding var selectedOption: SortOption
    @Binding var showingOptions: Bool

    var body: some View {
        Button(action: {
            showingOptions.toggle()
        }) {
            HStack {
                Text(selectedOption.rawValue)
                    .font(.app(.content2))
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
            }
            .padding(.leading, 8)
            .padding(.trailing, 8)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 16)
        .actionSheet(isPresented: $showingOptions) {
            ActionSheet(
                title: Text("정렬 기준")
                    .font(.app(.subHeadline2)),
                buttons: SortOption.allCases.map { option in
                    .default(Text(option.rawValue)
                        .font(.app(.content1))) {
                        selectedOption = option
                    }
                } + [.cancel(Text("취소")
                    .font(.app(.content1)))]
            )
        }
    }
}

struct MeetingCardView: View {
    let meeting: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .cornerRadius(12, corners: [.topLeft, .topRight])

                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red)
                                .frame(width: 40, height: 24)
                            Text(meeting.daysLeft)
                                .font(.app(.subContent1))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                    Spacer()
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(meeting.title)
                    .font(.app(.subHeadline2))
                    .fontWeight(.semibold)

                Text(meeting.date)
                    .font(.app(.content2))
                    .foregroundColor(.secondary)

                Text(meeting.location)
                    .font(.app(.content2))
                    .foregroundColor(.secondary)

                Text(meeting.address)
                    .font(.app(.subContent1))
                    .foregroundColor(.secondary)

                HStack {
                    Text(meeting.price)
                        .font(.app(.content2))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(meeting.participants)
                        .font(.app(.content2))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct MapViewButton: View {
    var body: some View {
        Button(action: {
            // 지도 보기 액션
        }) {
            HStack {
                Image(systemName: "map")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                Text("지도보기")
                    .font(.app(.content2))
                    .foregroundColor(.black)
            }
            .frame(width: 130, height: 40)
            .background(Color.white)
            .cornerRadius(25)
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
    }
}

struct FloatingActionButton: View {
    var body: some View {
        Button(action: {
        }) {
            HStack {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text("모임 만들기")
                    .font(.app(.content2))
                    .foregroundColor(.white)
            }
            .frame(width: 130, height: 40)
            .background(Color.black)
            .cornerRadius(25)
        }
    }
}


extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    MeetingListView()
}
