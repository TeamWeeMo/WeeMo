//
//  MeetingListComponents.swift
//  WeeMo
//
//  Created by 차지용 on 11/10/25.
//

import SwiftUI

// MARK: - 검색바
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
        .commonPadding()
    }
}

// MARK: - 필터 버튼
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
        }
        .commonButtonStyle(isSelected: false)
        .commonPadding()
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

// MARK: - 모임 카드
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
                    .foregroundColor(Color("textMain"))

                Text(meeting.date)
                    .font(.app(.content2))
                    .foregroundColor(Color("textSub"))

                Text(meeting.location)
                    .font(.app(.content2))
                    .foregroundColor(Color("textSub"))

                Text(meeting.address)
                    .font(.app(.subContent1))
                    .foregroundColor(Color("textSub"))

                HStack {
                    Text(meeting.price)
                        .font(.app(.content2))
                        .foregroundColor(Color("textSub"))

                    Spacer()

                    Text(meeting.participants)
                        .font(.app(.content2))
                        .foregroundColor(Color("textSub"))
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(12)
        .cardShadow()
    }
}

// MARK: - 지도 보기 버튼
struct MapViewButton: View {
    var body: some View {
        NavigationLink(destination: MeetingMapView()) {
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
            .cardShadow()
        }
    }
}

// MARK: - 플로팅 액션 버튼
struct FloatingActionButton: View {
    var body: some View {
        NavigationLink(destination: MeetingEditView()) {
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