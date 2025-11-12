//
//  MeetingDetailView.swift
//  WeeMo
//
//  Created by 차지용 on 11/8/25.
//

import SwiftUI

struct MeetingDetailView: View {
    let meeting: Meeting

    var body: some View {
        VStack(spacing: 0) {
            // 상단 이미지
            ZStack {
                Image("테스트 이미지")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()

            }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 제목과 주최자 정보
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(meeting.title)
                                .font(.app(.headline2))
                                .foregroundColor(Color("textMain"))

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
                        .padding(.top, 20)

                        HStack {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text("김")
                                        .font(.app(.content2))
                                        .fontWeight(.medium)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("주최자")
                                    .font(.app(.subContent1))
                                    .foregroundColor(Color("textSub"))
                                Text("김독서")
                                    .font(.app(.content2))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color("textMain"))
                            }

                            Spacer()
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)

                    Divider()

                    // 모임 정보
                    VStack(alignment: .leading, spacing: 20) {
                        InfoRow(icon: "calendar", title: "일정", content: "2025.11.15 (토) 14:00")

                        InfoRow(icon: "location", title: "장소", content: "모던 카페 라운지\n서울 강남구 테헤란로 123")

                        InfoRow(icon: "dollarsign.circle", title: "인원 참가비용", content: "15,000원", isBlue: true)

                        InfoRow(icon: "person.2", title: "참여 인원", content: "4 / 8명")

                        InfoRow(icon: "person.crop.circle", title: "조건", content: "성별 무관\n20~30대")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)

                    Divider()

                    // 모임 소개
                    VStack(alignment: .leading, spacing: 12) {
                        Text("모임 소개")
                            .font(.app(.subHeadline2))
                            .fontWeight(.semibold)
                            .foregroundColor(Color("textMain"))

                        Text("매주 토요일 오후에 모여 책을 읽고 이야기를 나누는 독서 모임입니다. 이번 주는 '여행 창작'을 함께 읽어요!")
                            .font(.app(.content2))
                            .foregroundColor(Color("textSub"))
                            .lineSpacing(4)

                        Text("일시")
                            .font(.app(.content2))
                            .fontWeight(.medium)
                            .foregroundColor(Color("textMain"))
                            .padding(.top, 8)

                        Text("2025.11.15 (토) 14:00")
                            .font(.app(.content2))
                            .foregroundColor(Color("textSub"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)

                    // 참가하기 버튼
                    Button(action: {
                        // 참가하기 액션
                    }) {
                        Text("15,000원 참가하고 참가하기")
                            .font(.app(.content1))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(Color.wmMain)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 34)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("모임 상세")
        .background(Color("wmBg"))
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let content: String
    var isBlue: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.app(.content2))
                    .foregroundColor(Color("textSub"))

                Text(content)
                    .font(.app(.content2))
                    .foregroundColor(isBlue ? .blue : Color("textMain"))
                    .fontWeight(isBlue ? .medium : .regular)
            }

            Spacer()
        }
    }
}

#Preview {
    MeetingDetailView(meeting: Meeting(
        title: "주말 독서 모임",
        date: "📅 2025.11.15 (토) 14:00",
        location: "📍 모던 카페 라운",
        address: "서울 강남구 테헤란로 123",
        price: "💰 15,000원/",
        participants: "👤 4 / 8명",
        imageName: "meeting1",
        daysLeft: "D-3"
    ))
}
