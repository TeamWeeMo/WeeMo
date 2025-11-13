//
//  SpaceDetailView.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI

struct SpaceDetailView: View {
    let space: Space
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // 이미지 캐러셀
                ImageCarouselView(imageURLs: space.imageURLs)

                VStack(alignment: .leading, spacing: Spacing.base) {
                    // 편의시설 태그
                    AmenityTagsView(tags: space.amenityTags)
                        .padding(.horizontal, Spacing.base)
                        .padding(.top, Spacing.base)

                    // 기본 정보
                    SpaceInfoSection(space: space)
                        .padding(.leading, Spacing.base)

                    // 구분선
                    Divider()
                        .padding(.horizontal, Spacing.base)

                    // 공간 소개
                    SpaceDescriptionSection(description: space.description)
                        .padding(.horizontal, Spacing.base)

                    // 날짜 선택 캘린더
                    DatePickerCalendarView()
                        .padding(.horizontal, Spacing.base)

                    // 예약하기 버튼
                    ReservationButton {
                        // TODO: 예약 로직 구현
                        print("예약하기 클릭")
                    }
                    .padding(.horizontal, Spacing.base)
                    .padding(.bottom, Spacing.base)
                }
            }
        }
        .background(Color("wmBg"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: Spacing.xSmall) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: AppFontSize.s16.rawValue))
                            .foregroundColor(Color("textMain"))

                        Text("공간 찾기")
                            .font(.app(.subHeadline1))
                            .foregroundColor(Color("textMain"))
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SpaceDetailView(space: Space.mockSpaces[0])
    }
}
