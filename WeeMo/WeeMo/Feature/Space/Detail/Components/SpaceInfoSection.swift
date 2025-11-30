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
                .font(.app(.headline4))
                .foregroundColor(.textMain)
            
            // 해시태그
            AmenityTagsView(tags: space.hashTags)
                .offset(y: -4)

            // 주소
            HStack(alignment: .top, spacing: Spacing.small) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.app(.content2))
                    .foregroundColor(.textSub)

                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text(space.address)
                        .font(.app(.content2))
                        .foregroundColor(.textMain)

                    if let roadAddress = space.roadAddress, !roadAddress.isEmpty {
                        Text(roadAddress)
                            .font(.app(.subContent1))
                            .foregroundColor(.textSub)
                    }
                }
            }
            
            
            // 가격
            HStack(spacing: Spacing.small) {
                Image(systemName: "wonsign.square")
                    .font(.app(.content2))
                    .foregroundColor(.textSub)
                
                Text(space.formattedPrice)
                    .font(.app(.content2))
                    .foregroundColor(.wmMain)
                Spacer()
                // 별점
                Image(systemName: "star.fill")
                    .font(.app(.content2))
                    //.font(.system(size: AppFontSize.s14.rawValue))
                    .foregroundColor(.yellow)

                Text(space.formattedDetailRating)
                    .font(.app(.content2))
                    .foregroundColor(.textMain)

            }
            .padding(.trailing, Spacing.base)

            // 편의시설 정보 (주차, 화장실, 최대인원)
            HStack(spacing: Spacing.base) {
                // 주차 정보
                HStack(spacing: Spacing.xSmall) {
                    Image(systemName: "car.fill")
                        .font(.app(.content2))
                        //.font(.system(size: AppFontSize.s14.rawValue))
                        .foregroundColor(.textSub)

                    Text(space.hasParking ? "주차 가능" : "주차 불가")
                        .font(.app(.content2))
                        .foregroundColor(Color("textSub"))
                }
                
                Spacer()
                
                // 화장실 정보
                HStack(spacing: Spacing.xSmall) {
                    Image(systemName: "figure.stand.dress.line.vertical.figure")
                        .font(.app(.content2))
                        //.font(.system(size: AppFontSize.s14.rawValue))
                        .foregroundColor(.textSub)

                    Text(space.hasBathRoom ? "화장실 있음" : "화장실 없음")
                        .font(.app(.content2))
                        .foregroundColor(.textSub)
                }
                
                Spacer()
                
                // 최대인원 정보
                HStack(spacing: Spacing.xSmall) {
                    Image(systemName: "person.2.fill")
                        .font(.app(.content2))
                        //.font(.system(size: AppFontSize.s14.rawValue))
                        .foregroundColor(.textSub)

                    Text("\(space.maxPeople)명까지")
                        .font(.app(.content2))
                        .foregroundColor(.textSub)
                }
            }
            .padding(.trailing, Spacing.base)
        }
    }
}
