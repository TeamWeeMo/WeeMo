//
//  SpaceInfoSection.swift
//  WeeMo
//
//  Created by Reimos on 2025-11-08.
//

import SwiftUI

struct SpaceInfoSection: View {
    let space: Space

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // 제목
            Text(space.title)
                .font(.app(.subHeadline1)) // 18 bold로 변경 필요
                .foregroundColor(Color("textMain"))
            
            // 해시태그
            AmenityTagsView(tags: space.hashTags)
                .offset(y: -4)
               // .padding(.horizontal, Spacing.base)

            // 주소
            HStack(alignment: .top, spacing: Spacing.small) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.app(.content2))
                    .foregroundColor(.textSub)

                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text(space.address)
                        .font(.app(.content2))
                        .foregroundColor(Color("textMain"))

                    if let roadAddress = space.roadAddress, !roadAddress.isEmpty {
                        Text(roadAddress)
                            .font(.app(.subContent1))
                            .foregroundColor(Color("textSub"))
                    }
                }
            }
            
            
            // 가격
            HStack(spacing: Spacing.small) {
                Image(systemName: "wonsign.square")
                    .font(.app(.content2))
                    .foregroundColor(.textSub)
                
                Text(space.formattedPrice)
                    .font(.app(.content2)) // bold 처리 필요
                    .foregroundColor(Color("wmMain"))
                Spacer()
                // 별점
                Image(systemName: "star.fill")
                    .font(.system(size: AppFontSize.s14.rawValue))
                    .foregroundColor(.yellow)

                Text(space.formattedDetailRating)
                    .font(.app(.content2))
                    .foregroundColor(Color("textMain"))

            }
            .padding(.trailing, Spacing.base)

            // 편의시설 정보 (주차, 화장실, 최대인원)
            HStack(spacing: Spacing.base) {
                // 주차 정보
                HStack(spacing: Spacing.xSmall) {
                    Image(systemName: "car.fill")
                        .font(.system(size: AppFontSize.s14.rawValue))
                        .foregroundColor(Color("textSub"))

                    Text(space.hasParking ? "주차 가능" : "주차 불가")
                        .font(.app(.content2))
                        .foregroundColor(Color("textSub"))
                }
                
                Spacer()
                
                // 화장실 정보
                HStack(spacing: Spacing.xSmall) {
                    Image(systemName: "figure.stand.dress.line.vertical.figure")
                        .font(.system(size: AppFontSize.s14.rawValue))
                        .foregroundColor(Color("textSub"))

                    Text(space.hasBathRoom ? "화장실 있음" : "화장실 없음")
                        .font(.app(.content2))
                        .foregroundColor(Color("textSub"))
                }
                
                Spacer()
                
                // 최대인원 정보
                HStack(spacing: Spacing.xSmall) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: AppFontSize.s14.rawValue))
                        .foregroundColor(Color("textSub"))

                    Text("\(space.maxPeople)명까지")
                        .font(.app(.content2))
                        .foregroundColor(Color("textSub"))
                }
            }
            .padding(.trailing, Spacing.base)
        }
    }
}
